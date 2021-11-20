require 'redis'

RSpec.describe "trimming a stream in redis" do
  # Redis supports trimming streams as values are added, but it's not clear in
  # the docs if trimming streams trims the items from consumer groups that
  # have yet to process those items.
  #
  # In this test we're going to create a stream, create a consumer group for it,
  # load the stream with lots of items, then test if the consumer group can see
  # all the items added since the group was created, or just the trimmed items.
  #
  let(:redis) { Redis.new }
  let(:stream) { "test-trimming-stream" }
  let(:group) { "test-trimming-consumer-group" }
  let(:consumer) { "test-treaming-consumer-1" }
  let(:all_ids) { 100.times.map { SecureRandom.uuid } }

  context "with a consumer group" do
    it "removes the stream entries from the consumer group" do
      redis.del stream
      redis.xgroup(:create, stream, group, "$", mkstream: true)
      all_ids.each { |id| redis.xadd stream, { id: id } }
      redis.xtrim(stream, 10)
      # binding.pry
      result = redis.xreadgroup(group, consumer, stream, ">", count: 1000)
      expect(result[stream].count).to eq(10)
    end
  end
end
