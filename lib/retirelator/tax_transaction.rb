module Retirelator
  class TaxTransaction < DecimalStruct
    attribute :id, default: -> { ULID.generate }
    attribute :type, Symbol, required: true
    attribute :year, required: true
    decimal :amount
    alias_method :gross_amount, :amount
    decimal :rate
    decimal :applied
    decimal :remaining
    attribute :description
    attribute :account

    def taxes_paid
      # there is no withholding in negative tax land
      return 0.to_d if applied.negative?
      (amount * percent).round(2)
    end
    alias_method :total, :taxes_paid

    def net_amount
      (gross_amount * (1 - percent)).round(2)
    end

    def percent
      rate / 100
    end

    def as_csv
      {
        "Year"            => year,
        "Type"            => type,
        "ID"              => id,
        "Account"         => account,
        "Description"     => description,
        "Taxable Amount"  => gross_amount,
        "Taxes Paid"      => taxes_paid,
        "Rate"            => rate,
        "Applied"         => applied,
        "Remaining"       => remaining,
      }
    end
  end

  # represents a collection/array of tax transactions
  class TaxTransactions
    def self.from_hash(maybe_array)
      Array.wrap(maybe_array).map { |value| TaxTransaction.from_hash(value) }
    end

    def self.to_hash(maybe_array)
      Array.wrap(maybe_array).map { |value| TaxTransaction.to_hash(value) }
    end
  end
end
