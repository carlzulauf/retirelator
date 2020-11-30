module Retirelator
  class DecimalStruct
    extend Dry::Initializer

    def self.attribute_names
      dry_initializer.options.map(&:target)
    end

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

    def attributes
      self.class.dry_initializer.attributes(self)
    end

    def as_json(*a)
      attributes.each_with_object({}) do |(key, value), jsonish|
        jsonish[key] = value.as_json
      end
    end
  end
end
