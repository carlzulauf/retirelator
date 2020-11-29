module Retirelator
  class DecimalStruct
    extend Dry::Initializer

    def self.decimal(attribute_name, **extra)
      option(attribute_name, Types::JSON::Decimal, **extra)
    end

    def round(decimal)
      decimal.round(2)
    end

    def to_currency(decimal)
      ActionController::Base.helpers.number_to_currency decimal
    end

    def to_string(decimal)
      round(decimal).to_s
    end
  end
end
