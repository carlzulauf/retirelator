module Retirelator
  class TaxTransaction < DecimalStruct
    option :type, Types::Coercible::Symbol
    decimal :amount
    decimal :rate
    decimal :remaining
  end

  Types.register_struct(TaxTransaction, collection: true)
end
