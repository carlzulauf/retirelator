module Retirelator
  # potentially a base class for CapitalGainsTaxes/IncomeTaxes
  class Taxes < DecimalStruct
    attribute :type
    attribute :year
    attribute :brackets, TaxBrackets

    def self.from_thresholds(type, thresholds)
      last = thresholds.count - 1
      brackets = thresholds.count.times.map do |i|
        options = { from: thresholds[i][0], rate: thresholds[i][1] }
        # last bracket is infinite, which is the default for :to
        options[:to] = thresholds[i + 1][0] unless i == last
        TaxBracket.new(options)
      end
      new(type: type, brackets: brackets)
    end

    def inflate(ratio, tax_year = year + 1)
      self.class.new(
        type: type,
        year: tax_year,
        brackets: brackets.map { |b| b.inflate(ratio) }
      )
    end

    def apply(amount, **extra)
      return [] if amount.zero?
      [].tap do |tax_transactions|
        loop do
          remainder   = current_bracket.apply(amount)
          applied     = amount - remainder
          tax_transactions << build_tax_transaction(applied, current_bracket, **extra)
          break if remainder.zero?
          amount = remainder
          # first bracket can go negative
          next if amount.negative? && current_bracket.first?
          # when bracket goes from negative to zero we might have a remainder and room in bracket
          next if amount.positive? && current_bracket.remaining?
          @current_bracket_index = current_bracket_index + (amount.positive? ? 1 : -1)
        end
      end
    end

    def net_debit(amount, **extra)
      return [] if amount.zero?
      [].tap do |tax_transactions|
        loop do
          gross, remainder = current_bracket.net_debit(amount)
          tax_transactions << build_tax_transaction(gross, current_bracket, **extra)
          break if remainder.zero?
          amount = remainder
          @current_bracket_index += 1 unless current_bracket.remaining?
        end
      end
    end

    def applied
      brackets.sum(&:applied)
    end

    def current_bracket
      brackets[current_bracket_index]
    end

    private

    def current_bracket_index
      @current_bracket_index ||= 0
    end

    def build_tax_transaction(applied, bracket, **extra)
      TaxTransaction.new(
        type:       type,
        year:       year,
        amount:     applied,
        rate:       bracket.rate,
        applied:    bracket.applied,
        remaining:  bracket.remaining,
        **extra
      )
    end
  end
end
