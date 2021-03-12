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

    # amount of random noise to introduce into growth/inflation
    # 0 is no noise
    # 1 is a reasonable amount of noise
    # amount greater than 1 is an extreme amount of noise
    decimal :noise,                     default: -> { 0 }

    # Number used to seed random number generator
    # Noise should be deterministic, meaning identical seeds should produce identical results
    option :seed, Types::Strict::Integer, default: -> { Random.new.seed }

    def inflation_ratio(noise_ratio = 1)
      ( (inflation_rate * noise_ratio) / 100 ) + 1
    end

    def annual_salary_growth_ratio(noise_ratio = 1)
      ( (salary_growth_rate * noise_ratio) / 100 ) + 1
    end

    def monthly_investment_growth_ratio
      monthly_ratio(investment_growth_rate)
    end

    # def daily_investment_growth_ratio
    #   daily_ratio(investment_growth_rate)
    # end

    def as_csv
      attributes.map { |k, v| { "Config Key" => k.to_s, "Value" => v.to_s } }
    end

    private

    def annual_ratio(annual_rate)
      (annual_rate / 100.to_d) + 1
    end

    # 10% represented as 1.10
    # Calculates a monthly compounding rate that achieves the target annual rate
    # Example:
    #   Annual rate of 6.5% (represented as decimal 6.5),
    #   Monthly rate of ~0.526% (returns decimal 1.00526)
    #   Compounding $1000 * 1.00526, 12 times, produces the expected $1065 total
    #   `12.times.reduce(1000) { |m| m * 1.00526 }` => ~1065
    def monthly_ratio(annual_rate)
      annual_ratio(annual_rate) ** (1.to_d / 12)
    end

    # def daily_ratio(annual_rate)
    #   annual_ratio(annual_rate) ** (1.to_d / 365)
    # end

    def random_desc
      "Simulation #{SecureRandom.hex(4)}"
    end
  end

  Types.register_struct(SimulationConfiguration)
end
