# stdlib
require "bigdecimal"
require "bigdecimal/util"
require "json"

# dependecies
require "dry-types"
require "dry-initializer"
require "active_support/json"
require "active_support/core_ext/enumerable"
require "active_support/core_ext/array/access"
require "active_support/core_ext/integer/time"
require "active_support/core_ext/module/attribute_accessors"
require "active_support/core_ext/object/json"

# utilities
require "retirelator/types"
require "retirelator/decimal_struct"

# domain models, ordered from independent to dependent types
require "retirelator/fixed_income"
require "retirelator/account"
require "retirelator/ira_account"
require "retirelator/roth_account"
require "retirelator/savings_account"
require "retirelator/retiree"
require "retirelator/simulation_configuration"
require "retirelator/tax_bracket"
require "retirelator/tax_transaction"

# depend on at least one other type
require "retirelator/transaction"
require "retirelator/taxes"
require "retirelator/tax_year"
require "retirelator/simulation"

module Retirelator
  def self.open(path = default_path)
    open_json File.read(path)
  end

  def self.save(simulation, path = default_path)
    File.write(path, JSON.pretty_generate(simulation.as_json))
  end

  def self.default_path
    "simulation.json"
  end

  def self.open_json(json)
    Simulation.new parse(json)
  end

  def self.parse(json)
    JSON.parse(json, symbolize_names: true)
  end
end
