require 'time'

class SessionTracker

  # 5 minutes. Same as Google Analytics.
  THRESHOLD = 5 * 60

  def initialize(type, redis = $redis)
    @type = type
    @redis = redis
  end

  def track(id, time = Time.now)
    return unless id
    # Add user id to a sorted set with the last-seen timestamp as score.
    # If they're already in there, update the timestamp.
    @redis.zadd key, time.to_i, id
    # Truncate the set once every 100 trackings or so.
    truncate(time) if truncate?
  rescue
    # Don't break the app we're embedded in if Redis goes down for a second.
  end

  def count(time = Time.now)
    # Count users with scores (last seen at) from N minutes ago up to now.
    users = @redis.zrangebyscore key, threshold(time), score(time)
    users.length
  end

  private

  def truncate(time)
    # Remove users with scores (last seen at) from the beginning of time
    # until just before N minutes ago.
    @redis.zremrangebyscore key, "-inf", "(#{threshold(time)}"
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
