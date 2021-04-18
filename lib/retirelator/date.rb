module Retirelator
  class Date
    def self.from_hash(str)
      ::Date.parse(str) if str.present?
    end

    def self.to_hash(date)
      date.presence&.to_s
    end

    def self.today
      ::Date.today
    end
  end
end
