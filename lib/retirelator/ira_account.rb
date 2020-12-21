module Retirelator
  class IraAccount < Account
    def default_name
      "IRA Account"
    end

    def description
      [
        "Pre-tax retirement account. Gains are not taxed.",
        "Contributions are tax deductible. Withdrawals are taxed as income.",
        "Withdrawals before age 59.5 may be penalized 10%.",
      ].join(" ")
    end

    def taxable_gains
      false
    end

    def taxable_distributions
      true
    end

    def deductible_contributions
      true
    end
  end

  Types.register_struct(IraAccount)
end
