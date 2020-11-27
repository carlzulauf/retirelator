lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'retirelator/version'

Gem::Specification.new do |spec|
  spec.name          = "retirelator"
  spec.version       = Retirelator::VERSION
  spec.authors       = ["Carl Zulauf"]
  spec.email         = ["carl@linkleaf.com"]

  spec.summary       = "Retirement Simulator"
  spec.description   = "Run some scenarios to find out how many years you can afford to live. A little like Oregon Trail, but for keeps."
  spec.homepage      = "https://github.com/carlzulauf/retirelator"
  spec.license       = "MIT"

  spec.add_dependency "opt_struct", ">= 1.0"
  spec.add_dependency "activesupport", ">= 4.0"
  spec.files         = `git ls-files`.split("\n").grep(/^lib/)
  spec.files        += %w(README.md retirelator.gemspec)
  spec.require_paths = ["lib"]
end
