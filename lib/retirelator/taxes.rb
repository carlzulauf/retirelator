module Retirelator
  # potentially a base class for CapitalGainsTaxes/IncomeTaxes
  class Taxes < DecimalStruct
    option :type
    option :brackets, Types::TaxBrackets, default: -> { Array.new }

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

    def apply(amount)
      [].tap do |tax_transactions|
        loop do
          bracket     = brackets[current_bracket_index]
          remainder   = bracket.apply(amount)
          applied     = amount - remainder
          tax_transactions << build_tax_transaction(applied, bracket)
          break if remainder.zero?
          amount = remainder
          @current_bracket_index = current_bracket_index + (amount.positive? ? 1 : -1)
        end
      end
    end

    def net_debit(amount)
      [].tap do |tax_transactions|
        loop do
          bracket = brackets[current_bracket_index]
          gross, remainder = bracket.net_debit(amount)
          tax_transactions << build_tax_transaction(gross, bracket)
          break if remainder.zero?
          amount = remainder
          @current_bracket_index += 1
        end
      end
    end

    private

    def current_bracket_index
      @current_bracket_index ||= 0
    end

    def build_tax_transaction(applied, bracket)
      TaxTransaction.new(
        type:       type,
        amount:     applied,
        rate:       bracket.rate,
        applied:    bracket.applied,
      )
    end
  end

  Types.register_struct(Taxes)
end
