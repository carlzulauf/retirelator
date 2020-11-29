describe Retirelator::Retiree do
  it "exists as a class" do
    expect(described_class).to be_a(Class)
  end

  describe ".new" do
    subject { described_class }
    it "can be initialized with no arguments" do
      expect(subject.new).to be_a(described_class)
    end

    it "can be initialized with a name and salary" do
      obj = subject.new(name: "Chris", salary: 500_000)
      expect(obj.name).to eq("Chris")
      expect(obj.salary).to eq(500_000)
    end

    it "coerces numeric attributes into decimal" do
      obj = subject.new(salary: 444_444, monthly_savings: "200.20")
      expect(obj.salary).to eq(444_444)
      expect(obj.salary).to be_a(BigDecimal)
      expect(obj.monthly_savings).to eq(200.20)
      expect(obj.monthly_savings).to be_a(BigDecimal)
    end
  end
end
