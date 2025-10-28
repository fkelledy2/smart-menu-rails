require 'test_helper'

class SlowQueryTest < ActiveSupport::TestCase
  def setup
    @slow_query = SlowQuery.create!(
      sql: 'SELECT * FROM restaurants WHERE user_id = $1',
      duration: 150.5,
      query_name: 'Restaurant Load',
      timestamp: Time.current,
      backtrace: 'app/controllers/restaurants_controller.rb:25',
    )
  end

  test 'should be valid with required attributes' do
    assert @slow_query.valid?
  end

  test 'should require sql' do
    @slow_query.sql = nil
    assert_not @slow_query.valid?
    assert_includes @slow_query.errors[:sql], "can't be blank"
  end

  test 'should require duration' do
    @slow_query.duration = nil
    assert_not @slow_query.valid?
    assert_includes @slow_query.errors[:duration], "can't be blank"
  end

  test 'should require positive duration' do
    @slow_query.duration = -1
    assert_not @slow_query.valid?
    assert_includes @slow_query.errors[:duration], 'must be greater than 0'
  end

  test 'should require timestamp' do
    @slow_query.timestamp = nil
    assert_not @slow_query.valid?
    assert_includes @slow_query.errors[:timestamp], "can't be blank"
  end

  test 'recent scope should return queries within timeframe' do
    old_query = SlowQuery.create!(
      sql: 'SELECT * FROM menus',
      duration: 200,
      timestamp: 2.hours.ago,
    )

    recent_queries = SlowQuery.recent(1.hour)
    assert_includes recent_queries, @slow_query
    assert_not_includes recent_queries, old_query
  end

  test 'slowest scope should order by duration' do
    SlowQuery.create!(
      sql: 'SELECT * FROM users',
      duration: 50,
      timestamp: Time.current,
    )

    slowest_queries = SlowQuery.slowest.limit(2)
    assert_equal @slow_query, slowest_queries.first
  end

  test 'by_duration scope should filter by minimum duration' do
    fast_query = SlowQuery.create!(
      sql: 'SELECT * FROM users',
      duration: 50,
      timestamp: Time.current,
    )

    slow_queries = SlowQuery.by_duration(100)
    assert_includes slow_queries, @slow_query
    assert_not_includes slow_queries, fast_query
  end

  test 'slowest_queries should return limited results' do
    5.times do |i|
      SlowQuery.create!(
        sql: "SELECT * FROM table_#{i}",
        duration: 100 + (i * 10),
        timestamp: Time.current,
      )
    end

    slowest = SlowQuery.slowest_queries(3, 1.hour)
    assert_equal 3, slowest.count
  end

  test 'by_pattern should find queries matching pattern' do
    SlowQuery.create!(
      sql: "SELECT * FROM restaurants WHERE name LIKE '%test%'",
      duration: 100,
      timestamp: Time.current,
    )

    matching_queries = SlowQuery.by_pattern('restaurants')
    assert matching_queries.count >= 2 # @slow_query and new query
  end

  test 'normalize_sql should normalize SQL queries' do
    sql1 = 'SELECT * FROM users WHERE id = $1'
    sql2 = 'SELECT * FROM users WHERE id = $2'

    normalized1 = SlowQuery.normalize_sql(sql1)
    normalized2 = SlowQuery.normalize_sql(sql2)

    assert_equal normalized1, normalized2
  end

  test 'normalize_sql should extract operation and table' do
    select_sql = 'SELECT * FROM restaurants WHERE user_id = $1'
    assert_equal 'SELECT restaurants', SlowQuery.normalize_sql(select_sql)

    insert_sql = 'INSERT INTO menus (name, restaurant_id) VALUES ($1, $2)'
    assert_equal 'INSERT menus', SlowQuery.normalize_sql(insert_sql)

    update_sql = 'UPDATE restaurants SET name = $1 WHERE id = $2'
    assert_equal 'UPDATE restaurants', SlowQuery.normalize_sql(update_sql)
  end

  test 'formatted_duration should format duration correctly' do
    @slow_query.duration = 150.5
    assert_equal '150.5 ms', @slow_query.formatted_duration

    @slow_query.duration = 1500
    assert_equal '1.5 s', @slow_query.formatted_duration
  end

  test 'table_name should extract table name' do
    assert_equal 'restaurants', @slow_query.table_name

    @slow_query.sql = "INSERT INTO menus (name) VALUES ('test')"
    assert_equal 'menus', @slow_query.table_name

    @slow_query.sql = "UPDATE users SET name = 'test'"
    assert_equal 'users', @slow_query.table_name

    @slow_query.sql = 'EXPLAIN SELECT * FROM complex_query'
    assert_equal 'complex_query', @slow_query.table_name
  end

  test 'potential_n_plus_one should detect N+1 patterns' do
    # Simple SELECT with WHERE clause and fast execution
    @slow_query.sql = 'SELECT * FROM restaurants WHERE user_id = $1'
    @slow_query.duration = 50 # Fast query
    assert @slow_query.potential_n_plus_one?

    # Complex query or slow execution
    @slow_query.sql = 'SELECT restaurants.*, COUNT(menus.id) FROM restaurants LEFT JOIN menus ON...'
    assert_not @slow_query.potential_n_plus_one?

    @slow_query.sql = 'SELECT * FROM restaurants WHERE user_id = $1'
    @slow_query.duration = 150 # Slow query
    assert_not @slow_query.potential_n_plus_one?
  end

  test 'group_by_pattern should group similar queries' do
    # Create similar queries
    SlowQuery.create!(
      sql: 'SELECT * FROM restaurants WHERE user_id = $1',
      duration: 100,
      timestamp: Time.current,
    )

    SlowQuery.create!(
      sql: 'SELECT * FROM restaurants WHERE user_id = $2',
      duration: 120,
      timestamp: Time.current,
    )

    SlowQuery.create!(
      sql: 'SELECT * FROM menus WHERE restaurant_id = $1',
      duration: 80,
      timestamp: Time.current,
    )

    grouped = SlowQuery.group_by_pattern

    assert grouped.key?('SELECT restaurants')
    assert grouped.key?('SELECT menus')
    assert grouped['SELECT restaurants'][:count] >= 2
  end
end
