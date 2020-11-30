# custom types need to be loaded later since they depend on domain models
#   which themselves depend on Types already existing

module Retirelator
  module Types
    def self.hash_constructor(klass)
      name = klass.name.split("::").last
      constructor = Constructor(klass) do |obj|
        Hash === obj ? klass.new(obj) : obj
      end
      const_set(name, constructor)
    end

    hash_constructor Retirelator::SimulationConfiguration
    hash_constructor Retirelator::Retiree

    Transactions = Array(Retirelator::Transaction)
  end
end
