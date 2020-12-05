module Retirelator
  class FixedIncome < DecimalStruct
    option :name, Types::Strict::String, default: -> { "Fixed Income Account" }
    option :start_date, Types::JSON::Date, default: -> { Date.today }
    option :stop_date, Types::JSON::Date.optional
    option :indexed, Types::Strict::Bool, default: -> { false }
    option :taxable, Types::Strict::Bool, default: -> { false }

    decimal :monthly_income, default: -> { 0 }

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
      return [[], 0] unless taxable
      transactions = income_tax.apply(amount)
      [transactions, amount - transactions.sum(&:total)]
    end

    def balance
      0 # fixed income doesn't have a balance
    end
  end
end