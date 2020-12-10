module Retirelator
  class SavingsAccount < Account
    # kind of the default so look at Account for most logic

    def default_name
      "Savings Account"
    end
  end
end
