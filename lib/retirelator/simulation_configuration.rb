module Retirelator
  class SimulationConfiguration < DecimalStruct
    option :description,  Types::Strict::String,  default: -> { random_desc }
    option :start_date,   Types::JSON::Date,      default: -> { Date.today }

    # annual rate of inflation, which increases ppp ratio every year
    decimal :inflation_rate,            default: -> { 1.9 }

    # amount of salary increase expected annually
    decimal :salary_growth_rate,        default: -> { inflation_rate }

    # growth in the size of each tax bracket, usually indexed for inflation
    decimal :tax_brackets_growth_rate,  default: -> { inflation_rate }

    # total annual returns on investment portfolio
    #  this is applied to all investment accounts (401k, IRAs, Savings, ...)
    decimal :investment_growth_rate,    default: -> { 6.5 }

    # ratio (0..1) of taxable investment returns expected to be short term gains (taxable as income)
    decimal :short_term_gains_ratio,    default: -> { 0.1 }

    private

    def random_desc
      "simulation #{SecureRandom.hex(4)}"
    end
  end
end
