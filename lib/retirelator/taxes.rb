module Retirelator
  # potentially a base class for CapitalGainsTaxes/IncomeTaxes
  class Taxes < DecimalStruct
    option :brackets, default: -> { Array.new }

    def apply(amount)
      [].tap do |tax_transactions|
        brackets.from(current_bracket_index).each_with_index do |bracket, i|
          amount = bracket.apply(amount)
          tax_transactions.push(amount)
          break if amount <= 0
          @current_bracket_index += i
        end
      end
    end

    def current_bracket_index
      @current_bracket_index ||= 0
    end
  end
end
