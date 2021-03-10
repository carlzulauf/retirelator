describe Retirelator::ScaledNoiseFactory do
  subject { described_class }

  describe ".new" do
    it "initializes with a seed and scale/ratio" do
      factory = subject.new seed: 123, noise: 0.15
      expect(factory).to be_a(subject)
      expect(factory.seed).to eq(123)
      expect(factory.noise).to eq(0.15)
    end

    it "can be initialized with a count" do
      factory = subject.new count: 10
      expect(factory.count).to eq(10)
    end
  end

  describe "instance methods" do
    let(:noise) { 0.15 }
    let(:options) { { seed: 123, noise: noise } }
    subject { described_class.new(**options) }

    describe "#rand" do
      it "returns a random ratio within noise factor of 1" do
        100.times { expect(subject.rand).to be_within(0.15).of(1) }
      end

      it "does not regularly return 1 exactly" do
        expect(
          100.times.count { subject.rand == 1 }
        ).to be < 10 # less than 10%, at least
      end

      context "with a larger scale" do
        let(:noise) { 1.5 }

        it "returns a random ratio within noise factor of 1" do
          100.times { expect(subject.rand).to be_within(1.5).of(1) }
        end

        it "does not regularly return 1 exactly" do
          expect(
            100.times.count { subject.rand == 1 }
          ).to be < 10
        end
      end
    end

    describe "#apply" do
      it "applies scaled noise to the supplied number" do
        100.times do
          expect(subject.apply(100)).to be_within(15).of(100)
        end
      end

      it "does not regularly return exactly the supplied number" do
        expect(
          100.times.count { subject.apply(666) == 666 }
        ).to be < 10
      end

      context "with a larger scale" do
        let(:noise) { 1.5 }

        it "applies scaled noise to the supplied number" do
          100.times do
            expect(subject.apply(100.to_d)).to be_within(150).of(100)
          end
        end
      end
    end
  end
end
