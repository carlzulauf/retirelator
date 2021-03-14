module Retirelator
  class TaxBracket < DecimalStruct
    decimal :from, default: -> { 0 }
    option :to, Types::JSON::Decimal.optional, default: -> { BigDecimal::INFINITY }
    decimal :rate, default: -> { 0 }
    decimal :applied, default: -> { 0 }

    def numeric_to
      to || BigDecimal::INFINITY
    end

    def description
      "$#{from.round(2)} to $#{to.round(2)} at #{rate.round(2)}%"
    end

    def range
      from...numeric_to
    end

    def size
      numeric_to - from
    end

    def remaining
      numeric_to - (applied + from)
    end

    def remaining?
      remaining.positive?
    end

    def first?
      from.zero?
    end

    def last?
      !to.finite?
    end

    def inflate(ratio)
      inflated_from = (from * ratio).ceil
      inflated_to = numeric_to.infinite? ? numeric_to : (numeric_to * ratio).ceil
      self.class.new(from: inflated_from, to: inflated_to, rate: rate)
    end
    alias_method :*, :inflate

    def apply(amount)
      amount.positive? ? debit(amount) : -credit(-amount)
    end

    def creditable_remaining
      return applied unless first?
      # transactions that credit first bracket to negative should be split in two
      applied.positive? ? applied : BigDecimal::INFINITY
    end

    def credit(amount)
      credit_amount = [creditable_remaining, amount].min
      @applied -= credit_amount
      amount - credit_amount
    end

    def debit(amount)
      # if bracket is negative, don't add more than needed to bring to zero
      debit_amount = [applied.negative? ? applied.abs : remaining, amount].min
      @applied += debit_amount
      amount - debit_amount
    end

    def net_debit(amount)
      net_ratio = 1 - (rate / 100)
      gross = (amount / net_ratio).round(2, BigDecimal::ROUND_UP)
      remainder = debit(gross)
      [gross - remainder, remainder * net_ratio]
    end
  end

  Types.register_struct(TaxBracket, collection: true)
end
