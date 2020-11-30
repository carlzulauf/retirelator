describe Retirelator::DecimalStruct do
  class TestParent < Retirelator::DecimalStruct
    option :foo
  end

  class TestChild < TestParent
    option :bar
  end

  describe ".attribute_names" do
    it "returns foo for parent" do
      expect(TestParent.attribute_names).to eq([:foo])
    end

    it "returns foo and bar for child" do
      expect(TestChild.attribute_names).to eq([:foo, :bar])
    end
  end
end
