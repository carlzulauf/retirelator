RSpec.describe Retirelator::Taxes do
  it "exists as a class" do
    expect(described_class).to be_a(Class)
  end

  let(:tax_bracket1) { Retirelator::TaxBracket.new(from: 0, to: 1000, rate: 0) }
  let(:tax_bracket2) { Retirelator::TaxBracket.new(from: 1000, to: 5000, rate: 10) }
  subject { described_class.new(type: :income, brackets: [tax_bracket1, tax_bracket2]) }

  describe "#apply" do
    it "applies amount to first bucket" do
      expect(tax_bracket1.remaining).to eq(1000)
      subject.apply(450)
      expect(tax_bracket1.remaining).to eq(550)
    end
    it "applies remainder to second bucket if amount exceeds first"
    it "returns a single tax transaction if amount fits in first bucket"
    it "returns multiple tax transactions if amount is spread across buckets"
  end
end
