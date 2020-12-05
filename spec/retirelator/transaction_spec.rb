describe Retirelator::Transaction do
  let(:required_attributes) do
    {
      account: "Savings",
      date: Date.today,
      description:  "Growth",
      gross_amount:   1_000,
      net_amount:     1_000,
      balance:      200_000,
    }
  end

  it "exists as a class" do
    expect(described_class).to be_a(Class)
  end

  describe ".new" do
    subject { described_class }

    it "can be initialized with the required attributes" do
      subject.new(required_attributes)
    end

    it "fails to initialize without the required attributes" do
      expect{ subject.new({}) }.to raise_error(KeyError)
    end

    it "defaults to no tax transactions" do
      transaction = subject.new(required_attributes)
      expect(transaction.tax_transactions).to be_a(Array)
      expect(transaction.tax_transactions).to be_empty
    end

    it "can be initialized with tax transactions" do
      tax_transactions = [
        Retirelator::TaxTransaction.new(
          type:       :income,
          amount:     50,
          rate:       5,
          remaining:  0,
        ),
        Retirelator::TaxTransaction.new(
          type:       :income,
          amount:     950,
          rate:       10,
          remaining:  3_050,
        )
      ]
      transaction = subject.new(
        required_attributes.merge(tax_transactions: tax_transactions)
      )
      expect(transaction.tax_transactions).to be_a(Array)
      expect(transaction.tax_transactions).to eq(tax_transactions)
    end
  end

  describe "instance methods" do
    let(:attributes) { required_attributes }
    subject { described_class.new(attributes) }

    it "returns true for #credit?" do
      expect(subject.credit?).to eq(true)
    end

    it "returns false for #debit?" do
      expect(subject.debit?).to eq(false)
    end

    context "with a negative gross+net" do
      let(:attributes) { required_attributes.merge(gross_amount: -64, net_amount: -64) }

      it "returns false for #credit?" do
        expect(subject.credit?).to eq(false)
      end

      it "returns true for #debit?" do
        expect(subject.debit?).to eq(true)
      end
    end
  end
end
