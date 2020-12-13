describe Retirelator::IraAccount do
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

  describe "#credit"
end
