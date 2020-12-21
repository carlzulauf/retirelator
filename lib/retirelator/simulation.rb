module Retirelator
  class Simulation < DecimalStruct
    option :current_date, Types::JSON::Date, default: -> { Date.today }
    option :retiree, Types::Retiree, default: -> { Retiree.new }
    option :configuration, Types::SimulationConfiguration, default: -> { SimulationConfiguration.new }
    # TODO option :tax_year,    Types::TaxYear, default: -> { starting_tax_year }
    option :ira_account, Types::IraAccount, default: -> { starting_ira }
    option :savings_account, Types::SavingsAccount, default: -> { starting_savings }
    option :roth_account, Types::RothAccount, default: -> { starting_roth }
    # TODO fixed income accounts
    option :transactions, Types::Transactions, default: -> { Array.new }

    private

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
