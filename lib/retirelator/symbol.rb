module Retirelator
  class Symbol
    def self.from_hash(str)
      case str
      when nil, "" then nil
      else
        str.to_sym
      end
    end

    def self.to_hash(sym)
      sym&.to_s
    end
  end
end
