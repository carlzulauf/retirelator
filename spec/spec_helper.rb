require "bundler/setup"
require "pry"
require "retirelator"

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
