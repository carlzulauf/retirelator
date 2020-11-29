module Retirelator
  class Transaction < DecimalStruct
    option :account, Types::Coercible::Symbol
    option :description, Types::Strict::String

    decimal :gross_amount
    decimal :net_amount # gross minus taxes
    decimal :balance

    option :tax_transactions, default: -> { Array.new }
  end
end
