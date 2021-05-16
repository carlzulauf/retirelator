module Retirelator
  class Simulation < DecimalStruct
    class CsvRow < Struct.new(:data)
      def as_csv
        data
      end
    end

    attribute :start_date,        Date,                     default: -> { Date.current_month }
    attribute :retiree,           Retiree
    attribute :configuration,     SimulationConfiguration
    attribute :tax_years,         TaxYears
    attribute :ira_account,       IraAccount,               default: -> { starting_ira }
    attribute :savings_account,   SavingsAccount,           default: -> { starting_savings }
    attribute :roth_account,      RothAccount,              default: -> { starting_roth }
    attribute :fixed_incomes,     FixedIncomes
    attribute :transactions,      Transactions
    attribute :tax_transactions,  TaxTransactions
    attribute :noiser,            ScaledNoiseFactory

    runtime_option :logger, default: -> { Logger.new(nil) }

    def accounts
      [savings_account, ira_account, roth_account]
    end

    def current_date
      @current_date ||= start_date
    end

    def current_tax_year
      return create_initial_tax_year unless defined?(@current_tax_year)
      @current_tax_year
    end

    def current_annual_salary
      current_tax_year.salary
    end

    def current_monthly_salary
      (current_annual_salary / 12).round(2)
    end

    def years_running
      current_date.year - start_date.year
    end

    def simulate!
      logger.info "Starting simulation"
      tax_ytd_income
      create_opening_transactions
      loop do
        next_month = Date.advance_months(1, current_date)
        logger.info "Advancing to #{next_month}"
        advance_tax_year unless current_tax_year.year == next_month.year
        @current_date = next_month
        simulate_month
        if current_date > retiree.target_death_date
          logger.warn "Congrats, you made it to to your target death date without going broke."
          break
        end
        if accounts.none? { |a| a.balance.positive? }
          logger.warn "You are broke on #{current_date}"
          break
        end
      end
      logger.info "Simulation complete"
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

    def monthly_balances
      keys = Set.new
      balances_by_date = {}
      transactions.each do |t|
        balances_by_date[t.date] ||= { "Date" => t.date }
        keys.each { |k| balances_by_date[t.date][k] ||= nil }
        next if t.balance.zero? && !keys.member?(t.account)
        keys << t.account
        balances_by_date[t.date][t.account] = t.balance
      end
      balances = balances_by_date.values
      # fill in missing balances
      balances.each_with_index do |date, i|
        keys.each do |key|
          date[key] = balances[i - 1][key] || 0 if date[key].nil? && i > 0
        end
      end
      balances.map { |row| CsvRow.new(row) }
    end

    def config_info
      spacer = { "Config Key" => "", "Value" => "" }
      [].tap do |info|
        retiree.as_csv.each { |row| info << CsvRow.new(row) }
        info << CsvRow.new(spacer)
        configuration.as_csv.each { |row| info << CsvRow.new(row) }
        info << CsvRow.new(spacer)
        info << CsvRow.new("Config Key" => "Starting Balances", "Value" => "")
        accounts.each { |a| info << CsvRow.new("Config Key" => a.name, "Value" => a.starting_balance) }
        fixed_incomes.each do |fa|
          info << CsvRow.new(spacer)
          info << CsvRow.new("Config Key" => "Fixed Income", "Value" => fa.name)
          info << CsvRow.new("Config Key" => "Start Date", "Value" => fa.start_date)
          info << CsvRow.new("Config Key" => "Stop Date", "Value" => fa.stop_date)
          info << CsvRow.new("Config Key" => "Monthly Income", "Value" => fa.starting_monthly_income)
          info << CsvRow.new("Config Key" => "Taxable", "Value" => fa.taxable)
          info << CsvRow.new("Config Key" => "Indexed for Inflation", "Value" => fa.indexed)
        end
      end
    end

    private

    def account_transactions(account)
      transactions.select { |transaction| transaction.account == account.name }
    end

    def advance_tax_year
      ira_contribution
      roth_contribution
      convert_to_roth
      inflate_fixed_incomes
      inflate_tax_year # ppp & salary too
    end

    def inflate_tax_year
      @current_tax_year = current_tax_year.next_year(
        inflation_ratio: noiser.apply(configuration.inflation_ratio, 0.15),
        salary_ratio: noiser.apply(configuration.annual_salary_growth_ratio, 0.5),
      )
      tax_years << @current_tax_year
    end

    def inflate_fixed_incomes
      fixed_incomes.each do |account|
        account.inflate(current_date, configuration.inflation_ratio)
      end
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
      extra_income = payout_fixed_incomes
      if current_date >= retiree.retirement_date
        extra_income = withdraw_monthly_allowance(extra_income)
      else
        apply_monthly_salary
        simulate_monthly_401k
        simulate_monthly_savings
      end
      save_extra_income(extra_income) if extra_income.positive?
    end

    def save_extra_income(amount)
      add_transactions savings_account.credit(
        current_date,
        amount,
        description: "Unused Fixed Income"
      )
    end

    def payout_fixed_incomes
      amount = 0
      fixed_incomes.each do |account|
        transactions = account.pay(retiree, current_date, current_tax_year.income)
        add_transactions transactions
        transactions.each { |t| amount += t.net_amount }
      end
      amount
    end

    def withdraw_monthly_allowance(extra_income = 0)
      allowance = (retiree.monthly_allowance * current_tax_year.ppp).round(2)
      if extra_income > allowance
        extra_income -= allowance
        allowance = 0
      else
        allowance -= extra_income
        extra_income = 0
      end
      if allowance.positive? && savings_account.balance.positive?
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
      extra_income
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
        next unless account.balance.positive?
        add_transactions account.grow(
          current_date,
          configuration.monthly_investment_growth_ratio(noiser.random_scaled_ratio),
          capital_gains: current_tax_year.capital_gains,
          income: current_tax_year.income,
          income_ratio: noiser.apply(configuration.short_term_gains_ratio)
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
      TaxYear.new(year: current_date.year, salary: retiree.salary).tap do |ty|
        @current_tax_year = ty
        tax_years << ty
      end
    end

    def create_initial_tax_transactions(account)
      return [] unless account.balance.positive? && account.taxable_gains
      cumulative_growth_ratio = configuration.monthly_investment_growth_ratio ** current_date.month
      gains = account.balance - (account.balance / cumulative_growth_ratio).round(2)
      short_term_gains = (gains * configuration.short_term_gains_ratio).round(2)
      long_term_gains = gains - short_term_gains
      TaxTransactions.new.tap do |taxes|
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
  end
end
