# stdlib
require "bigdecimal"
require "bigdecimal/util"
require "csv"
require "delegate"
require "json"
require "logger"
require "securerandom"
require "yaml"

# dependecies
require "ulid"
require "opt_struct"

# utilities
require "retirelator/date"
require "retirelator/symbol"
require "retirelator/decimal"
require "retirelator/decimal_struct"
require "retirelator/job_worker"
require "retirelator/job_manager"

# colletion types
require "retirelator/collection"
require "retirelator/fixed_incomes"
require "retirelator/tax_brackets"
require "retirelator/tax_transactions"
require "retirelator/tax_years"
require "retirelator/transactions"

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
require "retirelator/scaled_noise_factory"

# depend on at least one other type
require "retirelator/transaction"
require "retirelator/taxes"
require "retirelator/tax_year"
require "retirelator/simulation"

module Retirelator
  def self.redis
    @redis ||= Redis.current
  end

  def self.redis=(redis_client)
    @redis = redis_client
  end

  def self.open(path)
    if File.directory?(path)
      open_json(File.join(path, "simulation.json"))
    else
      case File.extname(path)
      when ".json", ".js" then open_json(path)
      when ".msgpack" then open_msgpack(path)
      else
        open_json(path)
      end
    end
  end

  def self.save(simulation, path, **json_options)
    if File.directory?(path)
      save_json(simulation, File.join(path, "simulation.json"))
      save_csv(simulation.tax_years, File.join(path, "tax_years.csv"))
      save_csv(simulation.transactions, File.join(path, "transactions.csv"))
      save_csv(simulation.tax_transactions, File.join(path, "taxes.csv"))
      save_csv(simulation.savings_transactions, File.join(path, "savings.csv"))
      save_csv(simulation.ira_transactions, File.join(path, "ira.csv"))
      save_csv(simulation.roth_transactions, File.join(path, "roth_ira.csv"))
    else
      case File.extname(path)
      when ".json", ".js" then save_json(simulation, path, **json_options)
      when ".msgpack" then save_msgpack(simulation, path)
      else
        save_json(simulation, path, **json_options)
      end
    end
  end

  def self.save_csv(collection, path)
    CSV.open(path, "w") do |csv|
      collection.each_with_index do |transaction, i|
        rows = Array(transaction.as_csv)
        csv << rows.first.keys if i == 0
        rows.each do |row|
          csv << row.values.map do |value|
            value = value.to_s
            value.empty? ? nil : value
          end
        end
      end
    end
  end

  def self.open_json(path)
    load_json File.read(path)
  end

  def self.load_json(json)
    params = JSON.parse(json, symbolize_names: true)
    Simulation.from_hash params
  end

  def self.save_json(simulation, path, pretty: false)
    json = pretty ? JSON.pretty_generate(simulation.as_json) : simulation.to_json
    File.write(path, json)
  end

  def self.save_msgpack(simulation, path)
    File.write(path, MessagePack.pack(simulation.as_json))
  end

  def self.open_msgpack(path)
    load_msgpack File.read(path)
  end

  def self.load_msgpack(msg)
    Simulation.from_hash MessagePack.unpack(msg)
  end

  def self.from_params(params, **runtime_options)
    params = default_params.merge(params)
    Simulation.from_hash(
      {
        "retiree"         => retiree_params(params),
        "configuration"   => configuration_params(params),
        "savings_account" => { balance: params["savings_balance"] },
        "ira_account"     => { balance: params["ira_balance"] },
        "roth_account"    => { balance: params["roth_balance"] },
        "fixed_incomes"   => fixed_incomes_params(params["fixed_incomes"]),
        "noiser"          => noiser_params(params),
      },
      **runtime_options
    )
  end

  def self.fixed_incomes_params(accounts_params)
    case accounts_params
    when nil, {}, [] then []
    else
      accounts_params
    end
  end

  def self.to_params(simulation)
    jsonish = simulation.to_hash
    retiree_params(jsonish["retiree"])
      .merge(configuration_params(jsonish["configuration"]))
      .merge(noiser_to_params(jsonish["noiser"]))
      .merge(
        "ira_balance"     => jsonish.dig("ira_account",     "balance"),
        "roth_balance"    => jsonish.dig("roth_account",    "balance"),
        "savings_balance" => jsonish.dig("savings_account", "balance"),
      )
  end

  def self.default_params
    to_params(Simulation.new).freeze
  end

  def self.retiree_params(params)
    params.slice(*%w{
      name salary
      retirement_date target_death_date
      percent_401k_contribution percent_401k_match max_percent_401k_match
      annual_ira_contribution annual_roth_contribution annual_roth_conversion
      monthly_savings monthly_allowance
      roth_conversion_taxes_from_savings
    })
  end

  def self.noiser_to_params(noiser_hash)
    {
      "noise" => noiser_hash["noise"],
      "rand_seed" => noiser_hash["seed"]
    }.compact
  end

  def self.noiser_params(params)
    { "noise" => params["noise"], "seed" => params["rand_seed"] }.compact
  end

  def self.configuration_params(params)
    params.slice(*%w{
      description start_date
      inflation_rate salary_growth_rate
      investment_growth_rate short_term_gains_ratio
    })
  end
end
