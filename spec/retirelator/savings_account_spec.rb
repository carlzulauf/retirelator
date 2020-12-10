describe Retirelator::SavingsAccount do
  describe ".new" do
    subject { described_class }

    it "can be initialized with no arguments" do
      expect(subject.new).to be_a(described_class)
    end

    it "can be initialized with balance and other arguments" do
      obj = subject.new(balance: 1_000)
      expect(obj.balance).to eq(1_000)
    end
  end

  describe "instance methods" do
    let(:attributes) do
      { balance: 2_020.02 }
    end
    let(:income) do
      Retirelator::Taxes.new(
        type: :income,
        brackets: [ Retirelator::TaxBracket.new(rate: 13) ]
      )
    end
    let(:capital_gains) do
      Retirelator::Taxes.new(
        type: :capital_gains,
        brackets: [ Retirelator::TaxBracket.new(rate: 10) ]
      )
    end
    let(:date) { Date.today }
    subject { described_class.new(attributes) }

    describe "#grow" do
      let(:growth_rate) { 1.075 }
      it "grows the balance by the specified ratio" do
        #  balance, +7.5% growth, -10% tax rate
        subject.grow(date, growth_rate, capital_gains: capital_gains)
        expect(subject.balance).to eq(2_156.37)
      end

      it "creates a transaction with the expected growth amount" do
        transactions = subject.grow(date, growth_rate, capital_gains: capital_gains)
        expect(transactions.count).to eq(1)
        expect(transactions[0]).to be_a(Retirelator::Transaction)
        expect(transactions[0].gross_amount).to eq(151.50)
        expect(transactions[0].net_amount).to eq(136.35) # -10% capital gains
      end

      it "applies transaction amount to capital gains by default" do
        transactions = subject.grow(date, growth_rate, capital_gains: capital_gains)
        expect(transactions.count).to eq(1)
        expect(transactions[0].tax_transactions.map(&:type).uniq).to eq([:capital_gains])
      end

      it "applies transaction amount to capital gains and income when ratio specified" do
        transactions = subject.grow(date, growth_rate, capital_gains: capital_gains, income: income, income_ratio: 0.2)
        expect(transactions.count).to eq(1)
        taxes = transactions[0].tax_transactions.group_by(&:type)
        expect(taxes[:income].sum(&:amount)).to eq(30.3)
        expect(taxes[:capital_gains].sum(&:amount)).to eq(121.2)
      end
    end

    describe "#debit" do
      it "reduces the balance by the specified amount" do
        subject.debit(date, 20.02)
        expect(subject.balance).to eq(2_000)
      end

      # withdrawal from savings is not taxable
      it "returns a transaction with the specified amount and no tax tranasctions" do
        transactions = subject.debit(date, 400)
        expect(transactions.count).to eq(1)
        expect(transactions[0].gross_amount).to eq(400)
        expect(transactions[0].tax_transactions).to be_empty
      end
    end

    describe "#credit" do
      it "increases balance by the specified amount" do
        subject.credit(date, 200)
        expect(subject.balance).to eq(2220.02)
      end

      it "is not taxable and contains no tax transactions" do
        transactions = subject.credit(date, 3000)
        expect(transactions.count).to eq(1)
        expect(transactions[0].gross_amount).to eq(3000)
        expect(transactions[0].net_amount).to eq(3000)
        expect(transactions[0].tax_transactions).to be_empty
      end
    end
  end
end
