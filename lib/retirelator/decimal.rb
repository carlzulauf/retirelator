module Retirelator
  class Decimal
    def self.from_hash(str)
      str.to_d
    end

    def self.to_hash(decimal)
      decimal&.to_s("F")
    end

    def self.to_currency(decimal)
      str = decimal.round(2).to_s("F")
      left_of_decimal, right_of_decimal = str.split(".")
      leading_digits = left_of_decimal.length % 3
      remaining_digits = left_of_decimal[leading_digits, left_of_decimal.length]
      parts = []
      parts << left_of_decimal[0, leading_digits] if leading_digits > 0
      parts.concat remaining_digits.scan(/\d{3}/)
      "$#{parts.join(',')}.#{right_of_decimal.ljust(2, '0')}"
    end

    def self.to_string(decimal)
      round(decimal).to_s
    end
  end
end
