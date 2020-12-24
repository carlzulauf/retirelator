# ActiveSupport::JSON for Object#as_json and date/time encoding/decoding
unless defined?(ActiveSupport::JSON)
  require "active_support/json"
  require "active_support/core_ext/object/json"
end

# mostly for improved #sum, but #index_by for feature detection
require "active_support/core_ext/enumerable" unless [].respond_to?(:index_by)

# For Array#from
require "active_support/core_ext/array/access" unless [].respond_to?(:from)

# Numeric #days, #months, #years, etc
require "active_support/core_ext/integer/time" unless 0.respond_to?(:years)
