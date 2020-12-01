module Retirelator
  class TaxYear < DecimalStruct
    option :year, Types::Strict::Integer, default: -> { Date.today.year }

    decimal :ppp, default: -> { 1 }
  end
end
