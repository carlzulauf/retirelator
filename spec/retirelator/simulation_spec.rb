describe Retirelator::Simulation do
  it "exists as a class" do
    expect(described_class).to be_a(Class)
  end

  describe ".new" do
    subject { described_class }
    let(:retiree) { Retirelator::Retiree.new(name: "Pat") }
    let(:configuration) do
      Retirelator::SimulationConfiguration.new(inflation_rate: 7.0)
    end

    let(:valid_attributes) do
      {
        retiree: retiree,
        current_date: 10.years.ago.to_date,
        configuration: configuration,
      }
    end

    it "can be initialized with no arguments" do
      expect(subject.new).to be_a(described_class)
    end

    it "can be initialized with valid attributes" do
      obj = subject.new(valid_attributes)
      expect(obj).to be_a(described_class)
      valid_attributes.each do |key, value|
        expect(obj.send(key)).to eq(value)
      end
    end
  end
end
