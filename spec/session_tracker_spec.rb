require 'session_tracker'

describe SessionTracker, "track" do

  let(:redis) { mock.as_null_object }

  it "should store the user in a sorted set scored by timestamp" do
    time = Time.at(1_000_000_000)
    redis.should_receive(:zadd).with("session_tracker_customer", 1_000_000_000, "abc123")
    tracker = SessionTracker.new("customer", redis)
    tracker.track("abc123", time)
  end

  it "should truncate old items from the set every now and then" do
    time = Time.at(1_000_000_000)
    redis.should_receive(:zremrangebyscore).with("session_tracker_customer", "-inf", "(999999700")
    tracker = SessionTracker.new("customer", redis)
    tracker.stub!(:truncate?).and_return(true)
    tracker.track("abc123", time)
  end

  it "should be able to track different types of sessions" do
    time = Time.at(1_000_000_000)
    redis.should_receive(:zadd).with("session_tracker_employee", 1_000_000_000, "abc456")
    tracker = SessionTracker.new("employee", redis)
    tracker.track("abc456", time)
  end

  it "should do nothing if the session id is nil" do
    redis.should_not_receive(:zadd)
    tracker = SessionTracker.new("employee", redis)
    tracker.track(nil)
  end

  it "should not raise any errors" do
    redis.should_receive(:zadd).and_raise('fail')
    tracker = SessionTracker.new("customer", redis)
    tracker.track("abc123", Time.now)
  end

end

describe SessionTracker, "active_users" do

  let(:redis) { mock.as_null_object }

  it "should get a count by timestamp range" do
    time = Time.at(1_000_000_000)
    redis.should_receive(:zrangebyscore).
      with("session_tracker_customer", 999_999_700, 1_000_000_000).
      and_return([ mock, mock ])

    SessionTracker.new("customer", redis).count(time).should == 2
  end

end
