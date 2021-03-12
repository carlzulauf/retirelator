module Retirelator
  class Account < DecimalStruct
    option :name, default: -> { default_name }
    decimal :balance, default: -> { 0 }
    decimal :starting_balance, default: -> { balance }

    def grow(date, ratio, capital_gains: nil, income: nil, income_ratio: 0)
      gross = (balance * (ratio - 1)).round(2)
      desc = gross.positive? ? "Growth" : "Loss"
      taxes = apply_tax(gross, capital_gains, taxable_gains, 1 - income_ratio, **tax_info(desc))
      taxes.concat apply_tax(gross, income, taxable_gains, income_ratio, **tax_info(desc))
      net = gross.positive? ? gross - taxes.sum(&:total) : gross
      @balance += net
      build_transaction("Growth", date, gross, net, taxes)
    end

    def debit(date, amount, income: nil, penalty: 0.to_d, description: "Debit", withhold_from: nil)
      withholding = (amount * (penalty / 100)).round(2)
      taxes = apply_tax(amount, income, taxable_distributions, **tax_info(description))
      withholding += taxes.sum(&:total)
      @balance -= amount
      if withhold_from
        external_withholding = [withholding, withhold_from.balance].min
        build_transaction(
          description,
          date,
          -amount,
          -(amount - (withholding - external_withholding)),
          taxes
        ) + withhold_from.debit(
          date,
          external_withholding,
          description: "Tax Withholding"
        )
      else
        build_transaction(description, date, -amount, -(amount - withholding), taxes)
      end
    end

    def net_debit(date, amount, income:, penalty: 0.to_d)
      if taxable_distributions
        description = "Debit (Net #{amount})"
        taxes = income.net_debit(amount, **tax_info(description))
        gross = taxes.sum(&:gross_amount)
        net   = taxes.sum(&:net_amount)
        net  -= (gross * (penalty / 100)).round(2)
        @balance -= gross
        build_transaction(description, date, -gross, -net, taxes)
      else
        debit(date, amount, income: income, penalty: penalty)
      end
    end

    def credit(date, amount, income: nil, description: "Credit")
      taxes = apply_tax(amount * -1, income, deductible_contributions, **tax_info(description))
      @balance += amount
      build_transaction(description, date, amount, amount, taxes)
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

    private

    def tax_info(description)
      { account: name, description: description }
    end

    def build_transaction(description, date, gross, net, taxes = [], account: self)
      [
        Transaction.new(
          account:          account.name,
          description:      description,
          date:             date,
          gross_amount:     gross,
          net_amount:       net,
          balance:          account.balance,
          tax_transactions: taxes,
        )
      ]
    end

    def apply_tax(amount, taxes, taxable, ratio = 1, **details)
      return [] if !taxable || ratio.zero?
      raise ArgumentError, "required taxes missing" if taxes.nil?
      taxes.apply( (amount * ratio).round(2), **details )
    end

    def default_name
      raise NotImplementedError, "default_name not defined for #{self.class}"
    end
  end
end
