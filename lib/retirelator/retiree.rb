module Retirelator
  class Retiree < DecimalStruct
    attribute :name, default: -> { "Pat" }

    attribute :date_of_birth,      Date, default: -> { Date.advance_years(-18) }
    attribute :target_death_date,  Date, default: -> { Date.advance_years(60) }
    attribute :retirement_date,    Date, default: -> { Date.advance_years(32) }

    decimal :salary,                    default: -> { 65_536 }
    decimal :percent_401k_contribution, default: -> { 4 }
    decimal :percent_401k_match,        default: -> { 100 }
    decimal :max_percent_401k_match,    default: -> { 4 }
    decimal :annual_ira_contribution,   default: -> { 0 }
    decimal :annual_roth_contribution,  default: -> { 0 }
    decimal :monthly_savings,           default: -> { 0 }
    decimal :monthly_allowance,         default: -> { 4_500 }

    decimal :annual_roth_conversion, default: -> { 0 }
    attribute :roth_conversion_taxes_from_savings, default: false
    attribute :roth_conversions_after_retirement,  default: false

    def contribution_rate_401k
      base_rate = percent_401k_contribution / 100
      match = ([percent_401k_contribution, max_percent_401k_match].min / 100) * (percent_401k_match / 100)
      base_rate + match
    end

    def as_csv
      attributes.map { |k, v| { "Config Key" => k.to_s, "Value" => v.to_s } }
    end
  end
end
