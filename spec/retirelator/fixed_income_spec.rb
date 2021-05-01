describe Retirelator::FixedIncome do
  let(:attributes) do
    {
      name: "Defined Benefit Plan",
      start_date: Date.new(2030, 1, 1),
      stop_date: Date.new(2040, 1, 1),
      monthly_income: 1_500,
      indexed: true,
      taxable: false,
    }
  end
  let(:taxes) do
    Retirelator::Taxes.new(
      type: :income,
      year: 2020,
      brackets: [ Retirelator::TaxBracket.new(rate: 13) ]
    )
  end
  let(:retiree) { double "Retiree" }

  subject { described_class.new(**attributes) }

  context "with no attributes" do
    it "can be initialized with defaults" do
      expect(described_class.new).to be_a(Retirelator::FixedIncome)
    end
  end

  context "with finite attributes" do
    it "initializes with expected values" do
      expect(subject.name).to eq("Defined Benefit Plan")
      expect(subject.start_date).to eq(Date.new(2030))
      expect(subject.stop_date).to eq(Date.new(2040))
      expect(subject.monthly_income).to eq(1_500)
    end

    describe "#pay" do
      it "returns no transactions before start date" do
        expect(subject.pay(retiree, Date.new(2020), taxes)).to be_empty
      end

      it "returns a transaction after start date" do
        transactions = subject.pay(retiree, Date.new(2031), taxes)
        expect(transactions.count).to eq(1)
        expect(transactions.first).to be_a(Retirelator::Transaction)
      end

      it "returns no transactions after end date" do
        expect(subject.pay(retiree, Date.new(2041), taxes)).to be_empty
      end
    end

    describe "#inflate" do
      it "returns the fixed income instance" do
        expect(subject.inflate(Date.today, 1.05)).to eq(subject)
      end

      it "ignores inflation when date is before start_date" do
        subject.inflate(Date.today, 1.05)
        expect(subject.monthly_income).to eq(1_500)
      end

      it "changes the monthly_income amount by the specified ratio" do
        subject.inflate(Date.new(2031), 1.05)
        expect(subject.monthly_income).to eq(1_575)
      end
    end
  end

  context "with infinite attributes" do
    let(:attributes) do
      {
        name: "Pension",
        start_date: Date.new(2030, 1, 1),
        stop_date: nil,
        monthly_income: 1_337,
        indexed: false,
        taxable: true,
      }
    end

    describe "#pay" do
      it "returns no transactions before the start date" do
        expect(subject.pay(retiree, Date.new(2025), taxes)).to be_empty
      end

      it "returns transactions far into the future" do
        transactions = subject.pay(retiree, Date.new(2099), taxes)
        expect(transactions.count).to eq(1)
        expect(transactions.first).to be_a(Retirelator::Transaction)
      end
    end
  end
end
