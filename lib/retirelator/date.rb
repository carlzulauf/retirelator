module Retirelator
  class Date
    def self.from_hash(str)
      case str
      when nil, "" then nil
      else
        ::Date.parse(str)
      end
    end

    def self.to_hash(date)
      case date
      when Date
        date.to_s("%Y-%m-%d")
      else
        nil
      end
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
