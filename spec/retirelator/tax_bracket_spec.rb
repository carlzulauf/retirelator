describe Retirelator::TaxBracket do
  subject { described_class.new(from: 0, to: 1000) }

  it "exists as a class" do
    expect(described_class).to be_a(Class)
  end

  describe "#apply" do
    it "reduces the balance remaining by the specified amount" do
      expect(subject.remaining).to eq(1000)
      expect(subject.apply(400)).to eq(0)
      expect(subject.remaining).to eq(600)
    end

    it "returns the remainder when applied amount is greater than balance remaining" do
      expect(subject.apply(1200)).to eq(200)
      expect(subject.remaining).to eq(0)
    end
  end

  describe "#range" do
    it "returns a non-inclusive range made from #from to #to" do
      expect(subject.range).to eq(0...1000)
    end
  end

  describe "#inflate" do
    it "inflates range by the expected ratio" do
      inflated = subject.inflate(1.055.to_d)
      expect(inflated.from).to eq(0)
      expect(inflated.to).to eq(1055)
      expect(inflated.range).to eq(0...1055)
    end
  end

  describe "#*" do
    it "inflates range by the expected ratio" do
      inflated = subject * 1.055.to_d
      expect(inflated.from).to eq(0)
      expect(inflated.to).to eq(1055)
      expect(inflated.range).to eq(0...1055)

    end
  end
end
