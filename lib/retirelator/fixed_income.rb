module Retirelator
  class FixedIncome < DecimalStruct
    attribute :name, default: "Fixed Income Account"
    attribute :start_date,  Date, default: nil
    attribute :stop_date,   Date, default: nil

    # Are withdrawals taxed as income?
    attribute :taxable, default: true

    # Indexed for inflation?
    attribute :indexed, default: true

    decimal :monthly_income, default: 0
    decimal :starting_monthly_income, default: -> { monthly_income }

    def pay(retiree, date, income_tax)
      return [] if start_date.nil? && date < retiree.retirement_date
      return [] if date < start_date
      return [] if stop_date && date > stop_date
      tax_transactions, net_income = pay_tax(monthly_income, income_tax)
      [
        Transaction.new(
          account:          name,
          description:      "Monthly Income",
          date:             date,
          gross_amount:     monthly_income,
          net_amount:       net_income,
          balance:          balance,
          tax_transactions: tax_transactions
        )
      ]
    end

    def pay_tax(amount, income_tax)
      return [TaxTransactions.new, amount] unless taxable
      transactions = income_tax.apply(amount, account: name, description: "Fixed Income Payment")
      [transactions, amount - transactions.sum(&:total)]
    end

    def inflate(date, ratio)
      return self if date < start_date
      self.monthly_income = (monthly_income * ratio).round(2)
      self
    end

    def balance
      0 # fixed income doesn't have a balance
    end

    def taxable_withdrawals?
      taxable
    end

    def taxable_gains?
      false
    end
  end
end
