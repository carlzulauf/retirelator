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

    def self.current_month(date = today)
      ::Date.new(date.year, date.month, 1)
    end

    def self.advance_years(delta, from = current_month)
      ::Date.new(from.year + delta, from.month, from.day)
    end

    def self.advance_months(delta, from = current_month)
      year = from.year
      month = from.month + delta
      while month < 1
        year -= 1
        month += 12
      end
      while month > 12
        year += 1
        month -= 12
      end
      ::Date.new(year, month, from.day)
    end
  end
end
