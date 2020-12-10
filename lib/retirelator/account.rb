module Retirelator
  class Account < DecimalStruct
    option :name, default: -> { default_name }
    decimal :balance, default: -> { 0 }

    def grow(date, ratio, capital_gains: nil, income: nil, income_ratio: 0)
      gross = (balance * (ratio - 1)).round(2)
      taxes = apply_tax(gross, capital_gains, taxable_gains, 1 - income_ratio)
      taxes.concat apply_tax(gross, income, taxable_gains, income_ratio)
      net = gross - taxes.sum(&:total)
      @balance += net
      [
        Transaction.new(
          account:          name,
          description:      "Growth",
          date:             date,
          gross_amount:     gross,
          net_amount:       net,
          balance:          balance,
          tax_transactions: taxes,
        )
      ]
    end

    def debit(date, amount, income: nil)
      gross = amount * -1
      taxes = apply_tax(gross, income, taxable_distributions)
      net = gross - taxes.sum(&:total)
      @balance += net
      [
        Transaction.new(
          account:          name,
          description:      "Debit",
          date:             date,
          gross_amount:     amount,
          net_amount:       net,
          balance:          balance,
          tax_transactions: taxes,
        )
      ]
    end

    def credit(date, amount, income: nil)
      taxes = apply_tax(amount * -1, income, deductible_contributions)
      @balance += amount
      [
        Transaction.new(
          account:          name,
          description:      "Credit",
          date:             date,
          gross_amount:     amount,
          net_amount:       amount,
          balance:          balance,
          tax_transactions: taxes,
        )
      ]
    end

    private

    def apply_tax(amount, taxes, taxable, ratio = 1)
      return [] if !taxable || ratio.zero?
      raise ArgumentError, "required taxes missing" if taxes.nil?
      taxes.apply (amount * ratio).round(2)
    end

    def default_name
      raise NotImplementedError, "default_name not defined for #{self.class}"
    end

    def taxable_gains
      true
    end

    def taxable_distributions
      false
    end

    def deductible_contributions
      false
    end
  end
end
