module Retirelator
  class Transaction < DecimalStruct
    option :account,      Types::Coercible::Symbol
    option :description,  Types::Strict::String
    option :date,         Types::JSON::Date

    decimal :gross_amount
    decimal :net_amount # gross minus taxes
    decimal :balance

    option :tax_transactions, default: -> { Array.new }

    def credit?
      gross_amount.positive?
    end

    def debit?
      gross_amount.negative?
    end
  end
end
