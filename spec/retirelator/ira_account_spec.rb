describe Retirelator::IraAccount do
  include_context "with income tax brackets"
  let(:attributes) do
    { balance: 100_000 }
  end
  subject { described_class.new(attributes) }

  describe "#grow" do
    it "grows the account with no tax transactions" do
      transaction = subject.grow(Date.today, 1.1.to_d).first
      expect(transaction.gross_amount).to eq(10_000)
      expect(transaction.net_amount).to eq(10_000)
      expect(transaction.tax_transactions).to be_empty
    end
  end

  describe "#debit" do
    it "records and withholds taxable portion" do
      transaction = subject.debit(Date.today, 20_000, income: income_taxes).first
      expect(transaction.gross_amount).to eq(-20_000)
      expect(transaction.net_amount).to eq(-17_350)
      expect(subject.balance).to eq(80_000)
    end
  end

  describe "#net_debit" do
    it "debits a gross amount large enough to net the specified amount after taxes" do
      transaction = subject.net_debit(Date.today, 20_000, income: income_taxes).first
      expect(transaction.net_amount).to be <= -20_000
      expect(transaction.net_amount).to be_within(1).of(-20_000)
      expect(transaction.gross_amount).to be_within(1).of(-23_117)
    end
  end

  describe "#credit" do
    it "reduces income tax by the contributed amount" do
      subject.credit(Date.today, 337, income: income_taxes)
      expect(tax_bracket1.remaining).to eq(1337)
    end

    it "creates a transaction with the specified amount for gross+net" do
      transaction = subject.credit(Date.today, 20_000, income: income_taxes).first
      expect(transaction.gross_amount).to eq(20_000)
      expect(transaction.net_amount).to eq(20_000)
    end
  end
end
