describe Retirelator do
  subject { described_class }

  describe ".open_json" do
    it "can open an existing simulation" do
      simulation = Retirelator.open_json("spec/support/valid_simulation.json")
      expect(simulation.retiree.name).to eq("Pat")
      expect(simulation.ira_account.balance).to eq(500_000)
    end
  end

  describe ".save" do
    include_context "with a valid simulation"
    let(:retiree) { Retirelator::Retiree.new(name: "Alex") }
    let(:savings_account) { Retirelator::SavingsAccount.new(balance: 1337) }
    let(:path) { "spec/support/tmp_simulation.json" }
    after { File.unlink path }

    it "can save simulation state to disk" do
      expect do
        Retirelator.save(simulation, path)
      end.to change { File.exist?(path) }.from(false).to(true)
      loaded = Retirelator.open(path)
      expect(loaded.retiree.name).to eq("Alex")
      expect(loaded.savings_account.balance).to eq(1337)
    end
  end

  describe ".from_params" do
    let(:sim1) { subject.from_params(params, logger: SPEC_LOGGER) }
    let(:sim2) { subject.from_params(params, logger: SPEC_LOGGER) }

    context "with no noise" do
      let(:params) do
        { "noise" => 0, "ira_balance" => 100_000_000 }
      end

      it "produces identical balances from multiple runs" do
        sim1.simulate!
        sim2.simulate!
        expect(sim1.ira_account.balance).to be > 0
        expect(sim1.ira_account.balance).to eq(sim2.ira_account.balance)
      end
    end

    context "with noise and the same seed" do
      let(:params) do
        { "noise" => 0.15, "ira_balance" => 100_000_000, "rand_seed" => 8675309 }
      end

      it "reflects the seed and noise in the noiser" do
        expect(sim1.noiser.seed).to eq(8675309)
        expect(sim1.noiser.noise).to eq(0.15)
      end

      it "produces identical balances from multiple runs" do
        sim1.simulate!
        sim2.simulate!
        expect(sim1.ira_account.balance).to be > 0
        expect(sim1.ira_account.balance).to eq(sim2.ira_account.balance)
      end
    end

    context "with noise and different seeds" do
      let(:params) { { "noise" => 0.15, "ira_balance" => 100_000_000 } }
      let(:sim1) { subject.from_params(params.merge("rand_seed" => 123), logger: SPEC_LOGGER) }
      let(:sim2) { subject.from_params(params.merge("rand_seed" => 456), logger: SPEC_LOGGER) }

      it "produces different results for the two simulations" do
        sim1.simulate!
        sim2.simulate!
        expect(sim1.ira_account.balance).to be > 0
        expect(sim2.ira_account.balance).to be > 0
        expect(sim1.ira_account.balance).not_to eq(sim2.ira_account.balance)
        sim1.summarize << sim2.summarize
      end
    end
  end
end
