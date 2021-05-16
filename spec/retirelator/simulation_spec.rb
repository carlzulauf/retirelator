describe Retirelator::Simulation do
  include_context "with a valid simulation"

  it "exists as a class" do
    expect(described_class).to be_a(Class)
  end

  describe ".new" do
    subject { described_class }

    it "can be initialized with no arguments" do
      expect(subject.new).to be_a(described_class)
    end

    it "can be initialized with valid attributes" do
      obj = subject.new(**simulation_attributes)
      expect(obj).to be_a(described_class)
      simulation_attributes.each do |key, value|
        expect(obj.send(key)).to eq(value)
      end

      expect(obj.ira_account.balance).to eq(500_000)
      expect(obj.roth_account.balance).to eq(25_000)
      expect(obj.savings_account.balance).to eq(75_000)
    end

    context "with transactions" do
      let(:transactions) do
        [
          Retirelator::Transaction.new(
            account:      "IRA",
            description:  "Opening Balance",
            date:         Date.today,
            gross_amount: 10_000,
            net_amount:   10_000,
            balance:      10_000,
          ),
          Retirelator::Transaction.new(
            account:      "Savings",
            description:  "Opening Balance",
            date:         Date.today,
            gross_amount: 12_000,
            net_amount:   12_000,
            balance:      12_000,
          )
        ]
      end

      it "can be initialized from Transaction instances" do
        obj = subject.new(**simulation_attributes.merge(transactions: transactions))
        expect(obj.transactions.count).to eq(2)
        expect(obj.transactions[0].gross_amount).to eq(10_000)
        expect(obj.transactions[1].balance).to eq(12_000)
      end

      it "can be initialized from transaction hashes" do
        hashes = transactions.map(&:to_hash)
        expect(hashes[0]).to be_a(Hash)
        obj = subject.from_hash(simulation.to_hash.merge("transactions" => hashes))
        expect(obj.transactions.count).to eq(2)
        expect(obj.transactions[0]).to be_a(Retirelator::Transaction)
        expect(obj.transactions[0].date).to eq(Date.today)
        expect(obj.transactions[1].net_amount).to eq(12_000)
      end
    end
  end

  describe "instance methods" do
    subject { described_class.new(**simulation_attributes) }

    describe "#as_json" do
      it "serializes nested objects into a JSON-like document" do
        doc = subject.as_json
        expect(doc).to be_a(Hash)
        expect(doc.keys.count).to be > 1
        expect(doc["retiree"]).to be_a(Hash)
      end

      it "returns a document that can loaded using .from_hash" do
        doc = subject.as_json
        obj = described_class.from_hash(doc)
        expect(obj.retiree.name).to eq("Pat")
        expect(obj.roth_account.balance).to eq(25_000)
        expect(obj.savings_account.balance).to eq(75_000)
        expect(obj.ira_account.balance).to eq(500_000)
      end
    end

    describe "#to_json" do
      it "returns a json document that can be parsed and loaded with .from_hash" do
        json = subject.to_json
        doc = JSON.parse(json)
        obj = described_class.from_hash(doc)
        expect(obj.retiree.name).to eq("Pat")
        expect(obj.roth_account.balance).to eq(25_000)
        expect(obj.savings_account.balance).to eq(75_000)
        expect(obj.ira_account.balance).to eq(500_000)
      end
    end

    context "with a completed simulation" do
      subject { simulation.tap(&:simulate!) }

      describe "#as_json" do
        it "can still serialize the simulation" do
          doc = subject.as_json
          expect(doc).to be_a(Hash)
          expect(doc.keys.count).to be > 1
          expect(doc["retiree"]).to be_a(Hash)
          expect(doc["transactions"].count).to be > 1
          expect(doc["transactions"].first).to be_a(Hash)
        end

        it "returns a doc that can be loaded using .from_hash" do
          doc = subject.as_json
          obj = described_class.from_hash(doc)
          expect(obj.retiree.name).to eq("Pat")
          expect(obj.transactions.count).to be > 1
          expect(obj.transactions.first).to be_a(Retirelator::Transaction)
        end
      end
    end
  end

end
