module Retirelator
  class FixedIncome < DecimalStruct
    option :name, Types::Strict::String, default: -> { "Fixed Income Account" }
    option :start_date, Types::JSON::Date, default: -> { Date.today }
    option :stop_date, Types::JSON::Date.optional, default: -> { nil }

    # Are withdrawals taxed as income?
    option :taxable, Types::Strict::Bool, default: -> { true }

    # Indexed for inflation?
    option :indexed, Types::Strict::Bool, default: -> { true }

    decimal :monthly_income, default: -> { 0 }
    decimal :starting_monthly_income, default: -> { monthly_income }

    def pay(date, income_tax)
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
      return [[], amount] unless taxable
      transactions = income_tax.apply(amount, account: name, description: "Fixed Income Payment")
      [transactions, amount - transactions.sum(&:total)]
    end

    def inflate(date, ratio)
      return self if date < start_date
      @monthly_income = (monthly_income * ratio).round(2)
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

  Types.register_struct(FixedIncome, collection: true)
end
