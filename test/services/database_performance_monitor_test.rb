require 'test_helper'

class DatabasePerformanceMonitorTest < ActiveSupport::TestCase
  test 'returns slow query threshold' do
    threshold = DatabasePerformanceMonitor.slow_query_threshold
    assert_kind_of Integer, threshold
    assert threshold > 0
  end

  test 'skips schema queries' do
    assert DatabasePerformanceMonitor.skip_query?('SELECT * FROM schema_migrations', 'SCHEMA')
  end

  test 'skips internal Rails queries' do
    assert DatabasePerformanceMonitor.skip_query?('SELECT * FROM schema_migrations', nil)
    assert DatabasePerformanceMonitor.skip_query?('SELECT * FROM ar_internal_metadata', nil)
  end

  test 'skips EXPLAIN queries' do
    assert DatabasePerformanceMonitor.skip_query?('EXPLAIN SELECT * FROM users', nil)
  end

  test 'skips transaction queries' do
    assert DatabasePerformanceMonitor.skip_query?('BEGIN', nil)
    assert DatabasePerformanceMonitor.skip_query?('COMMIT', nil)
    assert DatabasePerformanceMonitor.skip_query?('ROLLBACK', nil)
  end

  test 'does not skip regular queries' do
    assert_not DatabasePerformanceMonitor.skip_query?('SELECT * FROM users WHERE id = 1', 'User Load')
  end

  test 'normalizes SQL patterns' do
    sql = "SELECT * FROM users WHERE id = 123 AND name = 'John'"
    normalized = DatabasePerformanceMonitor.normalize_sql_pattern(sql)
    
    assert_equal "SELECT * FROM users WHERE id = ? AND name = ?", normalized
  end

  test 'normalizes SQL with placeholders' do
    sql = "SELECT * FROM users WHERE id = $1 AND name = $2"
    normalized = DatabasePerformanceMonitor.normalize_sql_pattern(sql)
    
    assert_equal "SELECT * FROM users WHERE id = ? AND name = ?", normalized
  end

  test 'normalizes SQL whitespace' do
    sql = "SELECT   *   FROM   users   WHERE   id = 1"
    normalized = DatabasePerformanceMonitor.normalize_sql_pattern(sql)
    
    assert_equal "SELECT * FROM users WHERE id = ?", normalized
  end

  test 'truncates long SQL patterns' do
    long_sql = "SELECT * FROM users WHERE " + ("id = 1 OR " * 50)
    normalized = DatabasePerformanceMonitor.normalize_sql_pattern(long_sql)
    
    assert normalized.length <= 200
  end

  test 'handles empty SQL' do
    normalized = DatabasePerformanceMonitor.normalize_sql_pattern('')
    assert_equal '', normalized
  end

  test 'handles SQL with multiple string literals' do
    sql = "SELECT * FROM users WHERE name = 'John' AND email = 'john@example.com'"
    normalized = DatabasePerformanceMonitor.normalize_sql_pattern(sql)
    
    assert_equal "SELECT * FROM users WHERE name = ? AND email = ?", normalized
  end

  test 'setup_monitoring does not raise errors' do
    assert_nothing_raised do
      DatabasePerformanceMonitor.setup_monitoring
    end
  end
end
