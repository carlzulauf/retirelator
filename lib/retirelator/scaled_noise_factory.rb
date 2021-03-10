module Retirelator
  class ScaledNoiseFactory < DecimalStruct
    # number between 0 and 1 represending the max percent change
    # this scale is used for every step where noise is introduced
    # small numbers work best
    # greater than 1 will break things
    decimal :noise, default: -> { 0 }

    option :seed,   Types::Strict::Integer, default: -> { Random.new.seed }
    option :count,  Types::Strict::Integer, default: -> { 0 }

    def rand
      base = (next_rand * 2) - 1 # random number between -1, 1
      1 + (base * noise)
    end

    def apply(value)
      value * rand
    end

    private

    def next_rand
      generator.rand.tap { @count += 1 }
    end

    def generator
      @generator ||= Random.new(seed).tap do |g|
        # iterate the generator if count is > 0
        count.times { g.rand }
      end
    end
  end

  Types.register_struct(ScaledNoiseFactory)
end
