module Retirelator
  class TaxYear < DecimalStruct
    attribute :year, required: true
    decimal :salary

    attribute :income, Taxes, default: -> { default_income_tax }
    attribute :capital_gains, Taxes, default: -> { default_capital_gains }
    decimal :ppp, default: -> { 1 }

    def next_year(inflation_ratio:, salary_ratio:)
      tax_year = year + 1
      self.class.new(
        year:           tax_year,
        salary:         (salary * salary_ratio).round(2),
        income:         income.inflate(inflation_ratio, tax_year),
        capital_gains:  capital_gains.inflate(inflation_ratio, tax_year),
        ppp:            (ppp * inflation_ratio).round(6),
      )
    end

    def as_csv
      income.brackets.map { |bracket| bracket_as_csv(bracket, "Income") } +
      capital_gains.brackets.map { |bracket| bracket_as_csv(bracket, "Capital Gains") }
    end

    private

    def bracket_as_csv(bracket, type)
      {
        "Year"      => year,
        "PPP"       => ppp,
        "Type"      => type,
        "From"      => bracket.from,
        "To"        => finite(bracket.to),
        "Rate"      => bracket.rate,
        "Applied"   => bracket.applied,
        "Remaining" => finite(bracket.remaining),
      }
    end

    def finite(number)
      number.finite? ? number : nil
    end

    def default_income_tax
      # https://taxfoundation.org/2021-tax-brackets/#brackets
      Taxes.from_hash(
        type: :income,
        year: year,
        brackets: [
          {                 to:   9_950,  rate: 10 },
          { from:   9_950,  to:  40_525,  rate: 12 },
          { from:  40_525,  to:  86_375,  rate: 22 },
          { from:  86_375,  to: 164_925,  rate: 24 },
          { from: 164_925,  to: 209_425,  rate: 32 },
          { from: 209_425,  to: 523_600,  rate: 35 },
          { from: 523_600,                rate: 37 },
        ]
      )
    end

    def default_capital_gains
      # https://taxfoundation.org/2021-tax-brackets/#capgains
      Taxes.from_hash(
        type: :capital_gains,
        year: year,
        brackets: [
          {                 to:  40_400,  rate: 0  },
          { from: 40_400,   to: 445_850,  rate: 15 },
          { from: 445_850,                rate: 20 },
        ]
      )
    end
  end
end
