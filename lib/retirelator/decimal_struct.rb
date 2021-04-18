module Retirelator
  class DecimalStruct < OptStruct.new
    # include OptStruct.build
    # cattr_accessor :runtime_attributes, instance_reader: true, default: []
    # extend Dry::Initializer
    shareable!

    class << self
      alias_method :runtime_option, :option

      def attributes
        {}.freeze
      end

      def attribute(name, type = nil, **options)
        add_attribute name, type
        options = { default: -> { type.new } }.merge(options) if type
        option name, **options
      end

      def attribute_names
        attributes.keys
      end

      def from_hash(input)
        init_with = {}
        attributes.each do |name, type|
          value = input[name] || input[name.to_s]
          init_with[name] = type.nil? ? value : type.from_hash(value)
        end
        self.new(**init_with)
      end

      def to_hash(instance)
        instance.to_hash
      end

      def decimal(name, **options)
        attribute(name, Decimal, **options)
      end

      private

      def add_attribute(name, type = nil)
        combined = attributes.merge(name => type)
        class_eval <<~RUBY
          def self.attributes
            #{combined.inspect}.freeze
          end
        RUBY
      end
    end

    def round(decimal, precision = 2)
      decimal.round(precision)
    end

    def to_currency(decimal)
      ActiveSupport::NumberHelper.number_to_currency decimal
    end

    def to_string(decimal)
      round(decimal).to_s
    end

    def to_hash(*)
      {}.tap do |serializable|
        self.class.attributes.each do |name, type|
          value = send(name)
          serializable[name.to_s] = type ? type.to_hash(value) : value
        end
      end
    end

    alias_method :as_json, :to_hash
  end
end
