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
        year: 2020,
        brackets: [ Retirelator::TaxBracket.new(rate: 13) ]
      )
    end
    let(:capital_gains) do
      Retirelator::Taxes.new(
        type: :capital_gains,
        year: 2020,
        brackets: [
          Retirelator::TaxBracket.new(rate: 10, to: 10_000),
          Retirelator::TaxBracket.new(rate: 15, from: 10_000)
        ]
      )
    end
    let(:date) { Date.today }
    let(:instance) { described_class.new(**attributes) }
    subject { instance }

    describe "#grow" do
      let(:growth_rate) { 1.075 }
      let(:growth_options) { { capital_gains: capital_gains } }
      subject { instance.grow(date, growth_rate, **growth_options) }
      let(:transaction) { subject.first }

      it "grows the balance by the specified ratio" do
        #  balance, +7.5% growth, -10% tax rate
        expect { subject }.to change { instance.balance }.from(2020.02).to(2156.37)
      end

      it "creates a transaction with the expected growth amount" do
        expect(subject.count).to eq(1)
        expect(transaction).to be_a(Retirelator::Transaction)
        expect(transaction.gross_amount).to eq(151.50)
        expect(transaction.net_amount).to eq(136.35) # -10% capital gains
      end

      it "applies transaction amount to capital gains" do
        expect(transaction.tax_transactions.map(&:type).uniq).to eq([:capital_gains])
      end

      context "with income tax and ratio specified" do
        let(:growth_options) do
          { capital_gains: capital_gains, income: income, income_ratio: 0.2 }
        end

        it "applies transaction amount to capital gains and income" do
          expect(subject.count).to eq(1)
          taxes = transaction.tax_transactions.group_by(&:type)
          expect(taxes[:income].sum(&:amount)).to eq(30.3)
          expect(taxes[:capital_gains].sum(&:amount)).to eq(121.2)
        end
      end

      context "with a growth ratio under 1 (a loss)" do
        let(:growth_rate) { 0.95 }

        it "creates a transaction with the expected gross and net" do
          expect(subject.count).to eq(1)
          expect(transaction.gross_amount).to eq(-101) # debit of 5%
          # without previous withholding to recoup, losses net the same as they gross
          expect(transaction.net_amount).to eq(transaction.gross_amount)
          # applies a negative amount to first tax bracket
          expect(capital_gains.current_bracket.applied).to eq(-101)
          # making the overall total negative as well
          expect(capital_gains.applied).to eq(-101)
        end

        it "credits the transaction amount to the tax bracket" do
          taxes, *extra = transaction.tax_transactions
          expect(extra).to be_empty
          expect(taxes.amount).to eq(-101)
          expect(capital_gains.applied).to eq(-101)
        end

        context "with previous growth transaction" do
          let(:attributes) { { balance: 100_000 } } # easier math
          # apply $9k to the first $10k tax bracket
          let!(:previous) { instance.grow(date, 1.09, capital_gains: capital_gains) }

          it "reverses a portion of the witholding previously applied" do
            expect(transaction.gross_amount).to eq(-5_405)
            # net is -10% lower than gross to repay previous withholding
            expect(transaction.net_amount).to eq(-4_864.5)
          end

          it "reduces the amount applied to taxes" do
            expect { subject }.to change { capital_gains.applied }.by(-5_405)
          end
        end
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
        expect(transactions[0].gross_amount).to eq(-400)
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
