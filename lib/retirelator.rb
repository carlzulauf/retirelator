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

# domain models
require "retirelator/retiree"
require "retirelator/simulation_configuration"
require "retirelator/tax_bracket"
require "retirelator/tax_transaction"
require "retirelator/taxes"
require "retirelator/transaction"

# custom types depend on domain models existing
require "retirelator/custom_types"

# these requires depend on custom type constraints, which depend on domain models
require "retirelator/simulation"
