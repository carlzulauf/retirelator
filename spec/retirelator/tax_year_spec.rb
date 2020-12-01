describe Retirelator::TaxYear do
  it "exists as a class" do
    expect(described_class).to be_a(Class)
  end

  describe ".new" do
    context "without parameters" do
      subject { described_class.new }

      it "initializes for the current year" do
        expect(subject.year).to eq(Date.today.year)
      end

      it "initializes with ppp at 1.0" do
        expect(subject.ppp).to eq(1.0)
      end
    end

    context "with valid parameters" do
      subject { described_class.new(valid_attributes) }

      let(:valid_attributes) do
        {
          year: 2017,
          ppp: 0.96,
        }
      end

      it "initializes with the specified year" do
        expect(subject.year).to eq(2017)
      end

      it "initializes with the specified ppp" do
        expect(subject.ppp).to eq(0.96)
      end
    end
  end
end
