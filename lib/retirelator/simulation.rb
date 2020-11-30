module Retirelator
  class Simulation < DecimalStruct
    option :current_date, Types::JSON::Date, default: -> { Date.today }
    option :retiree, Types::Retiree, default: -> { Retiree.new }
    option :configuration, Types::SimulationConfiguration, default: -> { SimulationConfiguration.new }
    # TODO option :tax_year,    Types::TaxYear, default: -> { starting_tax_year }
    # TODO option :ira_account, Types::IraAccount, default: -> { starting_ira_account }
    # TODO ... other accounts
    # TODO fixed income accounts
    option :transactions, Types::Transactions, default: -> { [] }
  end
end
