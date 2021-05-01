module Retirelator
  class Symbol
    def self.from_hash(str)
      str.to_sym if str.present?
    end

    def self.to_hash(sym)
      sym&.to_s
    end
  end
end
