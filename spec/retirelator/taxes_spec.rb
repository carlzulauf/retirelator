describe Retirelator::Taxes do
  it "exists as a class" do
    expect(described_class).to be_a(Class)
  end

  let(:tax_bracket1) { Retirelator::TaxBracket.new(from: 0, to: 1000, rate: 0) }
  let(:tax_bracket2) { Retirelator::TaxBracket.new(from: 1000, to: 5000, rate: 10) }
  let(:tax_bracket3) { Retirelator::TaxBracket.new(from: 5000, to: Float::INFINITY, rate: 15) }
  let(:brackets) { [tax_bracket1, tax_bracket2, tax_bracket3] }
  subject { described_class.new(type: :income, brackets: brackets) }

  describe "#apply" do
    it "applies amount to first bucket" do
      expect(tax_bracket1.remaining).to eq(1000)
      subject.apply(450)
      expect(tax_bracket1.remaining).to eq(550)
    end

    it "applies remainder to second bucket if amount exceeds first" do
      subject.apply(1500)
      expect(tax_bracket1.remaining).to eq(0)
      expect(tax_bracket2.remaining).to eq(3500)
    end

    it "returns a single tax transaction if amount fits in first bucket" do
      transactions = subject.apply(666)
      expect(transactions.count).to eq(1)
      first = transactions.first
      expect(first).to be_a(Retirelator::TaxTransaction)
      expect(first.type).to eq(:income)
      expect(first.amount).to eq(666)
      expect(first.rate).to eq(tax_bracket1.rate)
      expect(first.remaining).to eq(334)
    end

    it "returns multiple tax transactions if amount is spread across buckets" do
      transactions = subject.apply(1337)
      expect(transactions.count).to eq(2)
      tran1, tran2 = transactions

      expect(tran1.amount).to eq(1000)
      expect(tran1.type).to eq(:income)
      expect(tran1.rate).to eq(tax_bracket1.rate)
      expect(tran1.remaining).to eq(0)

      expect(tran2.amount).to eq(337)
      expect(tran2.type).to eq(:income)
      expect(tran2.rate).to eq(tax_bracket2.rate)
      expect(tran2.remaining).to eq(3663)
    end

    it "has infinite remaining in the last bucket no matter how much is applied" do
      subject.apply(130_000_000_000)
      expect(tax_bracket1.remaining).to eq(0)
      expect(tax_bracket2.remaining).to eq(0)
      expect(tax_bracket3.remaining).to eq(Float::INFINITY)
    end

    context "with negative amounts" do
      it "refills tax brackets" do
        subject.apply(3500) # empty the first bracket and part of the second
        subject.apply(-3500)
        expect(tax_bracket2.remaining).to eq(4000)
        expect(tax_bracket1.remaining).to eq(1000)
      end

      it "can grow the first tax bracket beyond its initial size" do
        subject.apply(3500)
        subject.apply(-4500)
        expect(tax_bracket1.applied).to eq(-1000)
        expect(tax_bracket1.remaining).to eq(2000)
      end
    end

  end
end
