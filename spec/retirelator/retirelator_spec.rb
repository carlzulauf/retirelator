describe Retirelator do
  describe ".open" do
    it "can open an existing simulation" do
      simulation = Retirelator.open("spec/support/valid_simulation.json")
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
        Retirelator.save(simulation, "spec/support/tmp_simulation.json")
      end.to change { File.exist?(path) }.from(false).to(true)
      loaded = Retirelator.open(path)
      expect(loaded.retiree.name).to eq("Alex")
      expect(loaded.savings_account.balance).to eq(1337)
    end
  end
end
