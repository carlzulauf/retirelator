module Retirelator
  class TaxYear < DecimalStruct
    option :year, Types::Strict::Integer, default: -> { Date.today.year }
    option :income, Types::Taxes, default: -> { default_income_tax }
    option :capital_gains, Types::Taxes, default: -> { default_capital_gains }
    decimal :ppp, default: -> { 1 }

    private

    def default_income_tax
      # last known single filer rates in USA
      Taxes.new(
        type: :income,
        brackets: [
          {                 to:   9_875,  rate: 10 },
          { from:   9_875,  to:  40_125,  rate: 12 },
          { from:  40_125,  to:  85_525,  rate: 22 },
          { from:  85_525,  to: 163_200,  rate: 24 },
          { from: 163_200,  to: 207_350,  rate: 32 },
          { from: 207_350,  to: 518_400,  rate: 35 },
          { from: 518_400,                rate: 37 },
        ]
      )
    end

    def default_capital_gains
      # last known single filer rates in USA
      Taxes.new(
        type: :capital_gains,
        brackets: [
          {                 to:  39_375,  rate: 0  },
          { from: 39_375,   to: 434_550,  rate: 15 },
          { from: 434_550,                rate: 20 },
        ]
      )
    end
  end

  Types.register_struct(TaxYear, collection: true)
end
