describe Retirelator::Retiree do
  it "exists as a class" do
    expect(described_class).to be_a(Class)
  end

  describe ".new" do
    it "can be initialized with no arguments" do
      expect(described_class.new).to be_a(described_class)
    end
  end
end
