module Retirelator
  class TaxTransaction < DecimalStruct
    option :id, Types::Strict::String, default: -> { ULID.generate }
    option :type, Types::Coercible::Symbol
    option :year, Types::Strict::Integer
    decimal :amount
    alias_method :gross_amount, :amount
    decimal :rate
    decimal :applied
    decimal :remaining
    option :description, Types::Strict::String.optional, default: -> { nil }
    option :account, Types::Strict::String.optional, default: -> { nil }

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

  Types.register_struct(TaxTransaction, collection: true)
end
