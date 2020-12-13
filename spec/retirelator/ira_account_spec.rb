describe Retirelator::IraAccount do
  include_context "with income tax brackets"
  let(:attributes) do
    {}
  end
  subject { described_class.new(attributes) }

  describe "#grow" do
    it "grows the account with no tax transactions"
  end

  describe "#debit" do
    it "records and withholds taxable portion"
  end

  describe "#credit" do
    it "reduces income tax by the contributed amount" do
      expect(tax_bracket1.remaining).to eq(1000)
      subject.credit(Date.today, 337, income: income_taxes)
      expect(tax_bracket1.remaining).to eq(1337)
    end
  end
end
