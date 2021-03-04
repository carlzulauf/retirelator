require "bundler/setup"
require "pry"
require "retirelator"

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

ROOT_DIR = File.expand_path(File.join(File.dirname(__FILE__), ".."))
LOG_DIR = File.join(ROOT_DIR, "log")
FileUtils.mkdir(LOG_DIR) unless File.exist?(LOG_DIR)
TEST_LOGGER = Logger.new(File.join(ROOT_DIR, "log", "test.log"))

shared_context "with income tax brackets" do
  let(:tax_bracket1) { Retirelator::TaxBracket.new(from: 0, to: 1000, rate: 0) }
  let(:tax_bracket2) { Retirelator::TaxBracket.new(from: 1000, to: 5000, rate: 10) }
  let(:tax_bracket3) { Retirelator::TaxBracket.new(from: 5000, to: BigDecimal::INFINITY, rate: 15) }
  let(:brackets) { [tax_bracket1, tax_bracket2, tax_bracket3] }
  let(:income_taxes) { Retirelator::Taxes.new(type: :income, brackets: brackets, year: 2020) }
end

shared_context "with a valid simulation" do
  let(:retiree) { Retirelator::Retiree.new(name: "Pat") }
  let(:configuration) do
    Retirelator::SimulationConfiguration.new(inflation_rate: 7.0)
  end
  let(:ira_account) { Retirelator::IraAccount.new(balance: 500_000) }
  let(:roth_account) { Retirelator::RothAccount.new(balance: 25_000) }
  let(:savings_account) { Retirelator::SavingsAccount.new(balance: 75_000) }

  let(:simulation_attributes) do
    {
      retiree:          retiree,
      start_date:       10.years.ago.to_date,
      configuration:    configuration,
      ira_account:      ira_account,
      roth_account:     roth_account,
      savings_account:  savings_account,
      logger:           TEST_LOGGER,
    }
  end

  let(:simulation) { Retirelator::Simulation.new(**simulation_attributes) }
end

# Uncomment this to re-generate spec/support/valid_simulation.json
# describe "prerequisites" do
#   include_context "with a valid simulation"
#   it "saves a valid simulation to spec/support" do
#     Retirelator.save(simulation, "spec/support/valid_simulation.json")
#   end
# end
