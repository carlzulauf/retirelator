module Retirelator
  class JobManager
    def self.enqueue(simulation_params, seeds)
      new(params: simulation_params).tap do |instance|
        instance.enqueue(seeds)
      end
    end

    attr_reader :job_id, :redis, :params, :balances

    def initialize(params:, job_id: generate_job_id, redis: Retirelator.redis)
      @job_id   = job_id
      @redis    = redis
      @params   = params
      @balances = 0.to_d
    end

    def enqueue(seeds)
      redis.set "retirelator:params:#{job_id}", dump(params)
      redis.sadd "retirelator:running:#{job_id}", seeds
      seeds.each do |seed|
        redis.lpush "retirelator:work", dump("job_id" => job_id, "seed" => seed)
      end
    end

    # right now the completed queue is per job. might want this to be global with a global manager listening
    def listen
      running_set = "retirelator:running:#{job_id}"
      loop do
        completed = redis.brpop "retirelator:completed:#{job_id}", 1
        if completed
          completed = load(completed[1])
          redis.srem running_set, completed["seed"]
          @balances += completed["balances"]
        end
        break if redis.scard(running_set) == 0
      end
      redis.del "retirelator:params:#{job_id}"
      # redis.del "retirelator:running:#{job_id}" # should be empty
      # redis.del "retirelator:completed:#{job_id}" # should be empty
      self
    end

    private

    def generate_job_id
      ULID.generate
    end

    def dump(obj)
      obj.to_yaml
    end

    def load(str)
      YAML.load str
    end
  end
end
