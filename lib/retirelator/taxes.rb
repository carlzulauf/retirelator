module Retirelator
  # potentially a base class for CapitalGainsTaxes/IncomeTaxes
  class Taxes < DecimalStruct
    option :type
    option :brackets, Types::TaxBrackets, default: -> { Array.new }

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

    private

    def current_bracket_index
      @current_bracket_index ||= 0
    end

    def build_tax_transaction(applied, bracket)
      TaxTransaction.new(
        type:       type,
        amount:     applied,
        rate:       bracket.rate,
        remaining:  bracket.remaining
      )
    end
  end
end
