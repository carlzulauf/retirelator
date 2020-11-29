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
  end
end
