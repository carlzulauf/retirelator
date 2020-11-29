# custom types need to be loaded later since they depend on domain models
#   which themselves depend on Types already existing

module Retirelator
  module Types
    SimulationConfiguration = Instance(Retirelator::SimulationConfiguration)
    Retiree                 = Instance(Retirelator::Retiree)
    Transactions            = Array(Retirelator::Transaction)
  end
end
