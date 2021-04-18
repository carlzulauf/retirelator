module Retirelator
  class Decimal
    def self.from_hash(str)
      str.to_d
    end

    def self.to_hash(decimal)
      decimal
    end
  end
end
