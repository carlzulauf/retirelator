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

      def from_hash(input = nil, **runtime_options)
        input, runtime_options = runtime_options, {} unless input
        init_with = {}
        attributes.each do |name, type|
          next unless input.key?(name) || input.key?(name.to_s)
          value = input[name] || input[name.to_s]
          init_with[name] = type.nil? ? value : type.from_hash(value)
        end
        self.new(**init_with.merge(runtime_options))
      end

      def to_hash(instance)
        instance.to_hash
      end

      def decimal(name, **options)
        options = { default: 0 }.merge(options)
        attribute(name, Decimal, **options)
        # overwrite the reader to cast to decimal on fetch
        class_eval <<~RUBY
          def #{name}
            options.fetch(:#{name}, 0)&.to_d
          end
        RUBY
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

    def to_json(*a)
      JSON.generate as_json, *a
    end
  end
end
