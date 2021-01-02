module Retirelator
  class Simulation < DecimalStruct
    option :start_date, Types::JSON::Date, default: -> { Date.today }
    option :retiree, Types::Retiree, default: -> { Retiree.new }
    option :configuration, Types::SimulationConfiguration, default: -> { SimulationConfiguration.new }
    option :tax_years, Types::TaxYears, default: -> { [starting_tax_year] }
    option :ira_account, Types::IraAccount, default: -> { starting_ira }
    option :savings_account, Types::SavingsAccount, default: -> { starting_savings }
    option :roth_account, Types::RothAccount, default: -> { starting_roth }
    option :fixed_incomes, Types::FixedIncomes, default: -> { Array.new }
    option :transactions, Types::Transactions, default: -> { Array.new }
    option :tax_transactions, Types::TaxTransactions, default: -> { Array.new }

    def accounts
      [savings_account, ira_account, roth_account]
    end

    def current_date
      @current_date ||= start_date.beginning_of_month
    end

    def current_tax_year
      return create_initial_tax_year if tax_years.empty?
      tax_years.last
    end

    def current_annual_salary
      starting_salary = retiree.salary
      return starting_salary if years_running.zero?
      (starting_salary * (configuration.annual_salary_growth_ratio ** years_running)).round
    end

    def current_monthly_salary
      (current_annual_salary / 12).round(2)
    end

    def years_running
      current_date.year - start_date.year
    end

    def simulate!
      tax_ytd_income
      create_opening_transactions
      loop do
        next_month = current_date.advance(months: 1)
        puts "Advancing to #{next_month}"
        advance_tax_year unless current_tax_year.year == next_month.year
        @current_date = next_month
        simulate_month
        if current_date > retiree.target_death_date
          puts "Congrats, you made it to to your target death date without going broke."
          break
        end
        if accounts.none? { |a| a.balance.positive? }
          puts "You are broke on #{current_date}"
          break
        end
      end
      self
    end

    def add_transactions(collection)
      collection = Array(collection)
      transactions.concat collection
      add_tax_transactions collection.flat_map(&:tax_transactions)
      transactions
    end

    def add_tax_transactions(collection)
      tax_transactions.concat Array(collection)
      tax_transactions
    end

    def savings_transactions
      account_transactions savings_account
    end

    def ira_transactions
      account_transactions ira_account
    end

    def roth_transactions
      account_transactions roth_account
    end

    private

    def account_transactions(account)
      transactions.select { |transaction| transaction.account == account.name }
    end

    def advance_tax_year
      ira_contribution
      roth_contribution
      convert_to_roth
      tax_years << current_tax_year.next_year(configuration.inflation_ratio)
    end

    def ira_contribution
      return if retiree.annual_ira_contribution.zero? || current_date > retiree.retirement_date
      add_transactions ira_account.credit(
        current_date,
        retiree.annual_ira_contribution,
        income: current_tax_year.income,
        description: "Annual IRA Contribution",
      )
    end

    def roth_contribution
      return if retiree.annual_roth_contribution.zero? || current_date > retiree.retirement_date
      add_transactions roth_account.credit(
        current_date,
        retiree.annual_roth_contribution,
        description: "Annual Roth IRA Contribution"
      )
    end

    def convert_to_roth
      return if retiree.annual_roth_conversion.zero? || (
        !retiree.roth_conversions_after_retirement && current_date > retiree.retirement_date
      )
      options = { income: current_tax_year.income }
      if retiree.roth_conversion_taxes_from_savings
        options[:withhold_from] = savings_account
      end
      add_transactions roth_account.convert_from(
        ira_account,
        current_date,
        retiree.annual_roth_conversion,
        **options
      )
    end

    def simulate_month
      simulate_account_growth
      if current_date >= retiree.retirement_date
        withdraw_monthly_allowance
      else
        apply_monthly_salary
        simulate_monthly_401k
        simulate_monthly_savings
      end
    end

    def withdraw_monthly_allowance
      allowance = (retiree.monthly_allowance * current_tax_year.ppp).round(2)
      if savings_account.balance.positive?
        from_savings = [allowance, savings_account.balance].min
        add_transactions savings_account.debit(current_date, from_savings, description: "Monthly Allowance") if from_savings.positive?
        allowance -= from_savings
      end
      if allowance.positive? && roth_account.balance.positive?
        from_roth = [allowance, roth_account.balance].min
        add_transactions roth_account.debit(current_date, from_roth, description: "Monthly Allowance") if from_roth.positive?
        allowance -= from_roth
      end
      if allowance.positive?
        add_transactions ira_account.net_debit(
          current_date,
          allowance,
          income: current_tax_year.income,
        )
      end
    end

    def apply_monthly_salary
      add_tax_transactions current_tax_year.income.apply(current_monthly_salary, description: "Monthly Salary")
    end

    def simulate_monthly_401k
      contribution = (current_monthly_salary * retiree.contribution_rate_401k).round(2)
      return unless contribution.positive?
      add_transactions ira_account.credit(
        current_date,
        contribution,
        income: current_tax_year.income,
        description: "Monthly 401(k) Contribution",
      )
    end

    def simulate_monthly_savings
      amount = retiree.monthly_savings
      return if amount.zero?
      add_transactions savings_account.credit(current_date, amount, description: "Monthly Savings")
    end

    def simulate_account_growth
      accounts.each do |account|
        next if account.balance.zero?
        add_transactions account.grow(
          current_date,
          configuration.monthly_investment_growth_ratio,
          capital_gains: current_tax_year.capital_gains,
          income: current_tax_year.income,
          income_ratio: configuration.short_term_gains_ratio,
        )
      end
    end

    def tax_ytd_income
      ytd_salary = current_monthly_salary * current_date.month
      add_tax_transactions current_tax_year.income.apply(ytd_salary, description: "YTD Income Tax")
    end

    def create_opening_transactions
      accounts.each do |account|
        add_transactions Transaction.new(
          account:          account.name,
          description:      "Opening Balance",
          date:             current_date,
          gross_amount:     account.balance,
          net_amount:       account.balance,
          balance:          account.balance,
          tax_transactions: create_initial_tax_transactions(account),
        )
      end
    end

    def create_initial_tax_year
      TaxYear.new(year: current_date.year).tap { |ty| tax_years << ty }
    end

    def create_initial_tax_transactions(account)
      return [] unless account.balance.positive? && account.taxable_gains
      cumulative_growth_ratio = configuration.monthly_investment_growth_ratio ** current_date.month
      gains = account.balance - (account.balance / cumulative_growth_ratio).round(2)
      short_term_gains = (gains * configuration.short_term_gains_ratio).round(2)
      long_term_gains = gains - short_term_gains
      [].tap do |taxes|
        if short_term_gains.positive?
          taxes.concat current_tax_year.income.apply(short_term_gains, description: "Estimated Taxable Gains YTD")
        end
        if long_term_gains.positive?
          taxes.concat current_tax_year.capital_gains.apply(long_term_gains, description: "Estimated Taxable Gains YTD")
        end
      end
    end

    def starting_ira
      IraAccount.new(balance: 0)
    end

    def starting_savings
      SavingsAccount.new(balance: 0)
    end

    def starting_roth
      RothAccount.new(balance: 0)
    end

    def starting_tax_year
      TaxYear.new(year: Date.today.year)
    end
  end
end
