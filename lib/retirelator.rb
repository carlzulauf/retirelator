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
