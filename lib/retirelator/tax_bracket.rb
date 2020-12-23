module Retirelator
  class TaxBracket < DecimalStruct
    decimal :from, default: -> { 0 }
    option :to, Types::JSON::Decimal.optional, default: -> { Float::INFINITY }
    decimal :rate, default: -> { 0 }
    decimal :applied, default: -> { 0 }

    def numeric_to
      to || Float::INFINITY
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

    def first?
      from.zero?
    end

    def inflate(ratio)
      self.class.new(from: from * ratio, to: numeric_to * ratio, rate: rate)
    end
    alias_method :*, :inflate

    def apply(amount)
      amount.positive? ? debit(amount) : -credit(-amount)
    end

    def creditable_remaining
      first? ? Float::INFINITY : applied
    end

    def credit(amount)
      credit_amount = [creditable_remaining, amount].min
      @applied -= credit_amount
      amount - credit_amount
    end

    def debit(amount)
      debit_amount = [remaining, amount].min
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
