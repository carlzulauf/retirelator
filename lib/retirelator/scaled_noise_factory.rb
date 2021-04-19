module Retirelator
  class ScaledNoiseFactory < DecimalStruct
    # number between 0 and 1 represending the max percent change
    # this scale is used for every step where noise is introduced
    # small numbers work best
    # greater than 1 will break things
    decimal :noise, default: 0

    attribute :seed,  default: -> { Random.new.seed }
    attribute :count, default: 0

    def random_scaled_ratio(scale = 1)
      base = (next_rand * 2) - 1 # random number between -1, 1
      ratio = 1 + (base * scale * noise)
      # scale decreasing ratio so it's proportional to increase
      # Example: 25% increase followed by 25% decrease is less than starting #
      #   1000 * 1.25 (25% increase) = $1250
      #   1250 * 0.75 (25% decrease) = $937.5 (too low. biases loss)
      #   1250 * 0.80 (20% decrease) = $1000 (1 / inverse [1.25])
      #   ... also works in reverse: 80% * 125% = 100%
      ratio > 1 ? ratio : invert_ratio(ratio)
    end

    def apply(value, scale = 1)
      value * random_scaled_ratio(scale)
    end

    def invert_ratio(start)
      inverse = 1 + (1 - start)
      1 / inverse
    end

    private

    def next_rand
      generator.rand.tap { self.count += 1 }
    end

    def generator
      @generator ||= Random.new(seed).tap do |g|
        # iterate the generator if count is > 0
        count.times { g.rand }
      end
    end
  end
end
