describe Retirelator do
  subject { described_class }

  describe ".from_params" do
    let(:sim1) { subject.from_params(params) }
    let(:sim2) { subject.from_params(params) }

    context "with no noise" do
      let(:params) do
        { noise: 0, ira_balance: 100_000_000 }
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
        { noise: 0.15, ira_balance: 100_000_000, rand_seed: 8675309 }
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
      let(:params) { { noise: 0.15, ira_balance: 100_000_000 } }
      let(:sim1) { subject.from_params(params.merge(rand_seed: 123)) }
      let(:sim2) { subject.from_params(params.merge(rand_seed: 456)) }

      it "produces different results for the two simulations" do
        sim1.simulate!
        sim2.simulate!
        expect(sim1.ira_account.balance).to be > 0
        expect(sim2.ira_account.balance).to be > 0
        expect(sim1.ira_account.balance).not_to eq(sim2.ira_account.balance)
      end
    end
  end
end
