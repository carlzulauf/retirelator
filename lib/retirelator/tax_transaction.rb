module Retirelator
  class TaxTransaction < DecimalStruct
    option :type, Types::Coercible::Symbol
    decimal :amount
    alias_method :gross_amount, :amount
    decimal :rate
    decimal :applied

    def taxes_paid
      (amount * (rate / 100)).round(2)
    end
    alias_method :total, :taxes_paid

  end

  Types.register_struct(TaxTransaction, collection: true)
end
