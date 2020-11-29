describe Retirelator::SimulationConfiguration do
  it "exists as a class" do
    expect(described_class).to be_a(Class)
  end

  describe ".new" do
    subject { described_class }

    it "can be initialized with no arguments" do
      expect(subject.new).to be_a(described_class)
    end
  end
end
