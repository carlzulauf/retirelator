# stdlib
require "bigdecimal"
require "bigdecimal/util"
require "json"
require "yaml"
require "securerandom"

# dependecies
require "ulid"
require "dry-types"
require "dry-initializer"
require "retirelator/active_support_features"

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
  def self.open(path)
    open_json File.read(path)
  end

  def self.save(simulation, path)
    File.write(path, JSON.pretty_generate(simulation.as_json))
  end

  def self.open_json(json)
    Simulation.new parse(json)
  end

  def self.parse(json)
    JSON.parse(json, symbolize_names: true)
  end

  def self.from_params(params)
    params = default_params.merge(params.symbolize_keys)
    retiree = retiree_params(params)
    config = configuration_params(params)
    savings_account = SavingsAccount.new(balance: params[:savings_balance])
    ira_account     = IraAccount.new(balance: params[:ira_balance])
    roth_account    = RothAccount.new(balance: params[:roth_balance])
    Simulation.new(
      retiree:          retiree,
      configuration:    config,
      savings_account:  savings_account,
      ira_account:      ira_account,
      roth_account:     roth_account,
    )
  end

  def self.to_params(simulation)
    jsonish = simulation.as_json
    retiree_params(jsonish[:retiree]).merge(
      configuration_params(jsonish[:configuration])
    ).merge(
      ira_balance:      jsonish.dig(:ira_account,     :balance),
      roth_balance:     jsonish.dig(:roth_account,    :balance),
      savings_balance:  jsonish.dig(:savings_account, :balance),
    )
  end

  def self.default_params
    to_params(Simulation.new)
  end

  def self.retiree_params(params)
    params.slice(*%i{
      name salary
      date_of_birth retirement_date target_death_date
      percent_401k_contribution percent_401k_match max_percent_401k_match
      annual_ira_contribution annual_roth_contribution annual_roth_conversion
      monthly_savings monthly_allowance
    })
  end

  def self.configuration_params(params)
    params.slice(*%i{
      description start_date
      inflation_rate salary_growth_rate
      investment_growth_rate short_term_gains_ratio
    })
  end
end
