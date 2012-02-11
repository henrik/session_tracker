require 'time'

class SessionTracker

  THRESHOLD = 3 * 60  # 3 minutes

  def initialize(type, redis = $redis)
    @type = type
    @redis = redis
  end

  def track(id, time = Time.now)
    return unless id
    @redis.zadd key, time.to_i, id
    truncate(time) if truncate?
  rescue
    # This is called for every request and is probably not essential for the app
    # so we don't want to raise errors just because redis is down for a few seconds.
  end

  def active_users(time = Time.now)
    @redis.zrangebyscore(key, threshold(time), score(time)).length
  end

  private

  def truncate(time)
    @redis.zremrangebyscore(key, "-inf", "(#{threshold(time)}")
  end

  def truncate?
    rand(100).zero?
  end

  def score(time)
    time.to_i
  end

  def threshold(time)
    score(time - THRESHOLD)
  end

  def key
    "session_tracker_#{@type}"
  end

end
