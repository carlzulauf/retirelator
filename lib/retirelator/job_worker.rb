module Retirelator
  class JobWorker
    attr_reader :id, :redis

    def initialize(id: nil, redis: Retirelator.redis)
      @id = id || generate_worker_id
      @redis = redis
    end

    def listen
      loop do
        task = redis.brpop "retirelator:work"
        if task
          task = load(task[1])
          params = get_params(task["job_id"]).merge("rand_seed" => task["seed"])
          simulation = Retirelator.from_params(params)
          simulation.simulate!
          task["balances"] = simulation.accounts.map(&:balance).sum
          redis.lpush "retirelator:completed:#{task["job_id"]}", dump(task)
        end
      end
    end

    private

    # simple single item cache
    def get_params(job_id)
      if @last_job_id == job_id
        @last_params
      else
        @last_job_id = job_id
        @last_params = load redis.get("retirelator:params:#{job_id}")
      end
    end

    def dump(obj)
      obj.to_yaml
    end

    def load(str)
      YAML.load str
    end

    def generate_worker_id
      ULID.generate
    end
  end
end
