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

    def simulate!
      tax_ytd_income
      create_opening_transactions
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

    private

    def tax_ytd_income
      ytd_salary = retiree.monthly_salary * current_date.month
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
