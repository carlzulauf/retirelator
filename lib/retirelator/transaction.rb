module Retirelator
  class Transaction < DecimalStruct
    option :id, Types::Strict::String, default: -> { ULID.generate }

    option :account,      Types::Strict::String
    option :description,  Types::Strict::String
    option :date,         Types::JSON::Date

    decimal :gross_amount
    decimal :net_amount # gross minus taxes
    decimal :balance

    option :tax_transactions, Types::TaxTransactions, default: -> { Array.new }

    def credit?
      gross_amount.positive?
    end

    def debit?
      gross_amount.negative?
    end
  end

  Types.register_struct(Transaction, collection: true)
end
