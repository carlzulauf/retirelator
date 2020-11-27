module Retirelator
  class TaxBracket < DecimalStruct
    decimal :from
    decimal :to
    decimal :rate, default: -> { 0 }
    decimal :remaining, default: -> { to - from }

    def description
      "$#{from.round(2)} to $#{to.round(2)} at #{rate.round(2)}%"
    end

    def range
      from...to
    end

    def inflate(ratio)
      self.class.new(from: from * ratio, to: to * ratio, rate: rate)
    end
    alias_method :*, :inflate

    # subtracts the supplied amount from the balance remaining
    # returns the remainder, or zero if there is no remainder
    def apply(amount)
      remainder = remaining - amount
      @remaining = [0, remainder].max
      remainder.negative? ? remainder * -1 : 0
    end
  end
end
