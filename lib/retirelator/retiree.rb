module Retirelator
  class Retiree < DecimalStruct
    option :name
    option :date_of_birth, Types::Params::Date

    decimal :salary,                    default: -> { 0 }
    decimal :percent_401k_contribution, default: -> { 4 }
    decimal :percent_401k_match,        default: -> { 100 }
    decimal :max_percent_401k_match,    default: -> { 4 }
    decimal :ira_balance,               default: -> { 0 }
    decimal :roth_balance,              default: -> { 0 }
    decimal :savings_balance,           default: -> { 0 }
    decimal :annual_ira_contribution,   default: -> { 0 }
    decimal :annual_roth_contribution,  default: -> { 0 }
    decimal :annual_roth_conversion,    default: -> { 0 }
    decimal :monthly_savings,           default: -> { 0 }
  end
end
