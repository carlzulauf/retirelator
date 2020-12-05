module Retirelator
  class TaxTransaction < DecimalStruct
    option :type, Types::Coercible::Symbol
    decimal :amount
    decimal :rate
    decimal :remaining

    def total
      (amount * (rate / 100)).round(2)
    end
  end

  Types.register_struct(TaxTransaction, collection: true)
end
