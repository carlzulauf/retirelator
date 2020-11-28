RSpec.describe Retirelator::Taxes do
  it "exists as a class" do
    expect(described_class).to be_a(Class)
  end

  let(:tax_bracket1) { Retirelator::TaxBracket.new(from: 0, to: 1000, rate: 0) }
  let(:tax_bracket2) { Retirelator::TaxBracket.new(from: 1000, to: 5000, rate: 10) }
  let(:tax_bracket3) { Retirelator::TaxBracket.new(from: 5000, to: Float::INFINITY) }
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
    end

    it "returns multiple tax transactions if amount is spread across buckets" do
      transactions = subject.apply(1337)
      expect(transactions.count).to eq(2)
    end

    it "has infinite remaining in the last bucket no matter how much is applied" do
      subject.apply(130_000_000_000)
      expect(tax_bracket1.remaining).to eq(0)
      expect(tax_bracket2.remaining).to eq(0)
      expect(tax_bracket3.remaining).to eq(Float::INFINITY)
    end
  end
end
