module Retirelator
  class TaxTransaction < DecimalStruct
    option :type, Types::Coercible::Symbol
    decimal :amount
    alias_method :gross_amount, :amount
    decimal :rate
    decimal :applied
    option :description, Types::Strict::String.optional, default: -> { nil }

    def taxes_paid
      (amount * (rate / 100)).round(2)
    end
    alias_method :total, :taxes_paid

    def net_amount
      (gross_amount * (1 - percent)).round(2)
    end

    def percent
      rate / 100
    end
  end

  Types.register_struct(TaxTransaction, collection: true)
end
