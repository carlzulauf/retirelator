module Retirelator
  class SavingsAccount < Account
    # kind of the default so look at Account for most logic

    def default_name
      "Savings Account"
    end

    def description
      [
        "Fully taxable account.",
        "Short and long term gains are taxed as",
        "income and capital gains respectively.",
        "Deposits and withdrawals are not taxed.",
      ].join(" ")
    end
  end
end
