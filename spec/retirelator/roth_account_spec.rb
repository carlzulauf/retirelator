describe Retirelator::RothAccount do
  include_context "with income tax brackets"
  let(:attributes) do
    { balance: 30_000 }
  end
  subject { described_class.new(attributes) }

  describe "#grow" do
    it "grows the account with no tax transactions" do
      transaction = subject.grow(Date.today, 1.1.to_d).first
      expect(transaction.gross_amount).to eq(3_000)
      expect(transaction.net_amount).to eq(3_000)
      expect(transaction.tax_transactions).to be_empty
    end
  end

  describe "#debit" do
    it "has no tax transactions and an identical net amount" do
      transaction = subject.debit(Date.today, 20_000, income: income_taxes).first
      expect(transaction.gross_amount).to eq(-20_000)
      expect(transaction.net_amount).to eq(-20_000)
      expect(transaction.tax_transactions).to be_empty
    end
  end

  describe "#net_debit" do
    it "debits a gross amount equal to the net amount specified" do
      transaction = subject.net_debit(Date.today, 20_000, income: income_taxes).first
      expect(transaction.net_amount).to eq(-20_000)
      expect(transaction.gross_amount).to eq(-20_000)
    end
  end

  describe "#credit" do
    it "creates a transaction with the specified amount for gross+net" do
      transaction = subject.credit(Date.today, 20_000, income: income_taxes).first
      expect(transaction.gross_amount).to eq(20_000)
      expect(transaction.net_amount).to eq(20_000)
    end
  end

  describe "#convert_from" do
    let(:ira_account) { Retirelator::IraAccount.new(balance: 100_000) }
    let(:extra) { {} }
    subject do
      described_class.new(attributes).convert_from(
        ira_account, Date.today, 10_000, income: income_taxes, **extra
      )
    end

    it "creates transactions to debit the IRA and credit the Roth IRA" do
      ira, roth = subject
      expect(ira.account).to eq("IRA Account")
      expect(ira.gross_amount).to eq(-10_000)
      expect(roth.account).to eq("Roth IRA Account")
    end

    it "withholds taxes from the IRA distribution by default" do
      ira, _ = subject
      expect(ira.gross_amount.abs).to be > ira.net_amount.abs
      expect(ira.tax_transactions).not_to be_empty
    end

    context "with a withholding account specified" do
      let(:savings_account) { Retirelator::SavingsAccount.new(balance: 10_000) }
      let(:extra) { { withhold_from: savings_account } }

      it "withholds taxes from the specified account" do
        ira, savings, roth = subject
        expect(ira.gross_amount).to eq(ira.net_amount)
        expect(savings.account).to eq("Savings Account")
        expect(roth.gross_amount.abs).to eq(ira.gross_amount.abs)
      end

      context "that has insuficient balance for withholding" do
        let(:savings_account) { Retirelator::SavingsAccount.new(balance: 10) }

        it "withholds taxes from the IRA" do
          ira, _savings, roth = subject
          expect(ira.gross_amount.abs).to be > ira.net_amount.abs
          expect(roth.account).to eq("Roth IRA Account")
        end

        it "withholds what it can from the savings account" do
          _ira, savings, _roth = subject
          expect(savings.gross_amount).to eq(-10)
        end
      end
    end
  end
end
