module Retirelator
  class Collection < Delegator
    class << self
      def to_hash(collection)
        type = collection.collection_type
        collection.map { |obj| type ? obj.to_hash : obj }
      end

      def from_hash(maybe_array)
        self.new.tap do |collection|
          Array.wrap(maybe_array).each do |item_from_hash|
            collection.add_from_hash(item_from_hash)
          end
        end
      end
    end

    def initialize(enum = nil)
      @enum = enum || Array.new
    end

    def __getobj__
      @enum
    end

    def collection_type
      nil
    end

    def to_hash(collection)
      map(&:to_hash)
    end

    def add_from_hash(value)
      type = collection_type
      push(type ? type.from_hash(value) : value)
    end
  end
end
