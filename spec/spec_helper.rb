require "bundler/setup"
require "pry"
require "retirelator"

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

shared_context "with income tax brackets" do
  let(:tax_bracket1) { Retirelator::TaxBracket.new(from: 0, to: 1000, rate: 0) }
  let(:tax_bracket2) { Retirelator::TaxBracket.new(from: 1000, to: 5000, rate: 10) }
  let(:tax_bracket3) { Retirelator::TaxBracket.new(from: 5000, to: Float::INFINITY, rate: 15) }
  let(:brackets) { [tax_bracket1, tax_bracket2, tax_bracket3] }
  let(:income_taxes) { Retirelator::Taxes.new(type: :income, brackets: brackets) }
end
