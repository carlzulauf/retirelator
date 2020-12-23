module Retirelator
  class Retiree < DecimalStruct
    option :name, default: -> { "Pat" }
    option :date_of_birth, Types::JSON::Date, default: -> { 18.years.ago.to_date }

    decimal :salary,                    default: -> { 65_536 }
    decimal :percent_401k_contribution, default: -> { 4 }
    decimal :percent_401k_match,        default: -> { 100 }
    decimal :max_percent_401k_match,    default: -> { 4 }
    decimal :annual_ira_contribution,   default: -> { 0 }
    decimal :annual_roth_contribution,  default: -> { 0 }
    decimal :annual_roth_conversion,    default: -> { 0 }
    decimal :monthly_savings,           default: -> { 0 }
    decimal :monthly_income,            default: -> { 4_500 }
  end

  Types.register_struct(Retiree)
end
