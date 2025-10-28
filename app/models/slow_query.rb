class SlowQuery < ApplicationRecord
  validates :sql, presence: true
  validates :duration, presence: true, numericality: { greater_than: 0 }
  validates :timestamp, presence: true

  scope :recent, ->(timeframe) { where('timestamp > ?', timeframe.ago) }
  scope :slowest, -> { order(duration: :desc) }
  scope :by_duration, ->(min_duration) { where(duration: min_duration..) }

  # Get the slowest queries in a timeframe
  def self.slowest_queries(limit = 10, timeframe = 1.hour)
    recent(timeframe).slowest.limit(limit)
  end

  # Get queries that match a pattern
  def self.by_pattern(pattern)
    where('sql ILIKE ?', "%#{pattern}%")
  end

  # Group slow queries by similar patterns
  def self.group_by_pattern
    all.group_by { |query| normalize_sql(query.sql) }
      .transform_values do |queries|
      { count: queries.count,
        avg_duration: queries.sum(&:duration) / queries.count.to_f, }
    end
  end

  # Normalize SQL for pattern matching
  def self.normalize_sql(sql)
    # Remove specific values and normalize whitespace
    normalized = sql.gsub(/\$\d+/, '?') # Replace $1, $2, etc. with ?
      .gsub(/\b\d+\b/, '?')                   # Replace numbers with ?
      .gsub(/'[^']*'/, '?')                   # Replace string literals with ?
      .gsub(/\s+/, ' ')                       # Normalize whitespace
      .strip

    # Extract the main operation and table
    if normalized =~ /^(SELECT|INSERT|UPDATE|DELETE)\s+.*?\s+FROM\s+(\w+)/i ||
       normalized =~ /^(INSERT)\s+INTO\s+(\w+)/i ||
       normalized =~ /^(UPDATE)\s+(\w+)/i
      "#{::Regexp.last_match(1).upcase} #{::Regexp.last_match(2)}"
    else
      normalized.truncate(100)
    end
  end

  # Format duration for display
  def formatted_duration
    if duration < 1000
      "#{duration.round(2)} ms"
    else
      "#{(duration / 1000).round(2)} s"
    end
  end

  # Extract table name from SQL
  def table_name
    if sql =~ /FROM\s+(\w+)/i || sql =~ /UPDATE\s+(\w+)/i || sql =~ /INSERT\s+INTO\s+(\w+)/i
      ::Regexp.last_match(1)
    else
      'unknown'
    end
  end

  # Check if query might be an N+1 problem
  def potential_n_plus_one?
    # Look for simple SELECT queries that might be repeated
    sql.match?(/SELECT\s+.*\s+FROM\s+\w+\s+WHERE\s+\w+\s*=\s*[$?]/i) && duration < 100
  end
end
