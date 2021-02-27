module Retirelator
  module Types
    include Dry.Types()

    def self.register_struct(klass, collection: false)
      name = klass.name.split("::").last
      constructor = Constructor(klass) do |obj|
        Hash === obj ? klass.new(**obj) : obj
      end
      const_set(name, constructor)
      const_set("#{name}s", Array(const_get(name))) if collection
    end
  end
end
