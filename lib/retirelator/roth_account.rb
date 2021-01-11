module Retirelator
  class RothAccount < Account
    def default_name
      "Roth IRA Account"
    end

    def description
      [
        "Post-tax retirement account. Gains are not taxed.",
        "Contributions are not tax deductible. Qualified withdrawals are not taxed.",
        "Contribution amounts can be withdrawn without penalty.",
        "Premature distribution of non-contribution amounts is taxed as income and penalized 10%",
      ].join(" ")
    end

    def taxable_gains
      false
    end

    def taxable_distributions
      false
    end

    def deductible_contributions
      false
    end

    def convert_from(ira, date, amount, income:, withhold_from: nil)
      distribution = ira.debit(date, amount,
        description: "Roth Conversion Distribution",
        income: income,
        withhold_from: withhold_from
      )
      contribution = credit(date, distribution.first.net_amount.abs,
        description: "Roth Conversion Contribution"
      )
      distribution + contribution
    end
  end
  Types.register_struct(RothAccount)
end
