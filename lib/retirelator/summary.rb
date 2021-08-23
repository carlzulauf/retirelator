module Retirelator
  class Summary
    attr_reader :report

    def initialize(report = report_skeleton)
      @report = report
    end

    def add_simulation(sim)
      by_date = Hash[ sim.dates.map { |s| [s.strftime("%Y-%m-%d"), {}] } ]
      last_balances = {}
      sim.transactions.each do |t|
        by_date[t.date.strftime("%Y-%m-%d")][t.account] = t.balance
      end
      report["accounts"] = sim.accounts.map(&:name)
      report["accounts"].each { |name| last_balances[name] = 0.to_d }
      report["simulations"] << (sim.noiser.noise == 0 ? 0 : sim.noiser.seed)
      by_date.each_with_index do |(date, all_balances), i|
        balances = report["accounts"].map do |name|
          last_balances[name] = [all_balances[name] || last_balances[name], 0.to_d].max
        end
        if existing_col = report["columns"][i]
          existing_col["totals"] << balances.sum
          existing_col["balances"] << balances
        else
          report["columns"] << {
            "date"      => date,
            "totals"    => [ balances.sum ],
            "balances"  => [ balances ],
          }
        end
      end
      self
    end

    def <<(other)
      report["simulations"].concat other.report["simulations"]
      report["columns"].each_with_index do |col, i|
        other_col = other.report["columns"][i]
        raise "dates don't match" unless col["date"] == other_col["date"]
        col["totals"].concat other_col["totals"]
        col["balances"].concat other_col["balances"]
      end
      self
    end

    def to_hash(*)
      report
    end
    alias_method :as_json, :to_hash

    def to_json(*a)
      JSON.generate as_json, *a
    end

    private

    def report_skeleton
      {
        "accounts"    => [],
        "simulations" => [],
        "columns"     => [],
      }
    end
  end
end
