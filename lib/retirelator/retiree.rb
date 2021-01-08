module Retirelator
  class Retiree < DecimalStruct
    option :name, default: -> { "Pat" }

    option :date_of_birth,      Types::JSON::Date, default: -> { 18.years.ago.to_date }
    option :target_death_date,  Types::JSON::Date, default: -> { 60.years.from_now.to_date }
    option :retirement_date,    Types::JSON::Date, default: -> { 32.years.from_now.to_date }

    decimal :salary,                    default: -> { 65_536 }
    decimal :percent_401k_contribution, default: -> { 4 }
    decimal :percent_401k_match,        default: -> { 100 }
    decimal :max_percent_401k_match,    default: -> { 4 }
    decimal :annual_ira_contribution,   default: -> { 0 }
    decimal :annual_roth_contribution,  default: -> { 0 }
    decimal :monthly_savings,           default: -> { 0 }
    decimal :monthly_allowance,         default: -> { 4_500 }

    decimal :annual_roth_conversion, default: -> { 0 }
    option :roth_conversion_taxes_from_savings, Types::Strict::Bool, default: -> { false }
    option :roth_conversions_after_retirement, Types::Strict::Bool, default: -> { false }

    def contribution_rate_401k
      base_rate = percent_401k_contribution / 100
      match = ([percent_401k_contribution, max_percent_401k_match].min / 100) * (percent_401k_match / 100)
      base_rate + match
    end

    def as_csv
      attributes.map { |k, v| { "Config Key" => k.to_s, "Value" => v.to_s } }
    end
  end

  Types.register_struct(Retiree)
end
