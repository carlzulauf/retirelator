module Retirelator
  # potentially a base class for CapitalGainsTaxes/IncomeTaxes
  class Taxes < DecimalStruct
    option :type
    option :brackets, Types::TaxBrackets, default: -> { Array.new }

    def apply(amount)
      [].tap do |tax_transactions|
        brackets.from(current_bracket_index).each_with_index do |bracket, i|
          transaction, amount = apply_to_bracket(amount, bracket)
          tax_transactions << transaction unless transaction.amount.zero?
          break if amount <= 0
          @current_bracket_index += i
        end
      end
    end

    private

    def apply_to_bracket(amount, bracket)
      remainder = bracket.apply(amount)
      transaction = build_tax_transaction(amount - remainder, bracket)
      [transaction, remainder]
    end

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
