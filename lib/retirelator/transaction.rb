module Retirelator
  class Transaction < DecimalStruct
    attribute :id, default: -> { ULID.generate }

    attribute :account,     required: true
    attribute :description, required: true
    attribute :date, Date,  required: true

    decimal :gross_amount
    decimal :net_amount # gross minus taxes
    decimal :balance

    option :tax_transactions, TaxTransactions, default: -> { Array.new }

    def credit?
      gross_amount.positive?
    end

    def debit?
      gross_amount.negative?
    end

    def as_csv
      {
        "ID"              => id,
        "Date"            => date,
        "Account"         => account,
        "Description"     => description,
        "Gross Amount"    => gross_amount,
        "Net Amount"      => net_amount,
        "Balance"         => balance,
      }
    end
  end
end
