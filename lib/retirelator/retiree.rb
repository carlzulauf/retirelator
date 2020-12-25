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
    decimal :annual_roth_conversion,    default: -> { 0 }
    decimal :monthly_savings,           default: -> { 0 }
    decimal :monthly_allowance,         default: -> { 4_500 }

    def monthly_salary
      (salary / 12).round(2)
    end
  end

  Types.register_struct(Retiree)
end
