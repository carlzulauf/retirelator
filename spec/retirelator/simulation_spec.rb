describe Retirelator::Simulation do
  it "exists as a class" do
    expect(described_class).to be_a(Class)
  end

  let(:retiree) { Retirelator::Retiree.new(name: "Pat") }
  let(:configuration) do
    Retirelator::SimulationConfiguration.new(inflation_rate: 7.0)
  end

  let(:attributes) do
    {
      retiree: retiree,
      current_date: 10.years.ago.to_date,
      configuration: configuration,
      ira_account: Retirelator::IraAccount.new(balance: 500_000),
      roth_account: Retirelator::RothAccount.new(balance: 25_000),
      savings_account: Retirelator::SavingsAccount.new(balance: 75_000),
    }
  end

  describe ".new" do
    subject { described_class }

    it "can be initialized with no arguments" do
      expect(subject.new).to be_a(described_class)
    end

    it "can be initialized with valid attributes" do
      obj = subject.new(attributes)
      expect(obj).to be_a(described_class)
      attributes.each do |key, value|
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
        obj = subject.new(attributes.merge(transactions: transactions))
        expect(obj.transactions.count).to eq(2)
        expect(obj.transactions[0].gross_amount).to eq(10_000)
        expect(obj.transactions[1].balance).to eq(12_000)
      end

      it "can be initialized from transaction hashes" do
        hashes = transactions.map(&:as_json)
        expect(hashes[0]).to be_a(Hash)
        obj = subject.new(attributes.merge(transactions: hashes))
        expect(obj.transactions.count).to eq(2)
        expect(obj.transactions[0]).to be_a(Retirelator::Transaction)
        expect(obj.transactions[0].date).to eq(Date.today)
        expect(obj.transactions[1].net_amount).to eq(12_000)
      end
    end
  end

  describe "instance methods" do
    subject { described_class.new(attributes) }

    describe "#as_json" do
      it "serializes nested objects into a JSON-like document" do
        doc = subject.as_json
        expect(doc).to be_a(Hash)
        expect(doc.keys).to be_many
        expect(doc[:retiree]).to be_a(Hash)
      end

      it "returns a document that can loaded using .new" do
        doc = subject.as_json
        obj = described_class.new(doc)
        expect(obj.retiree.name).to eq("Pat")
        expect(obj.savings_account.balance).to eq(75_000)
        expect(obj.ira_account.balance).to eq(500_000)
      end
    end
  end
end
