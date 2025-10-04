namespace :db do
  namespace :performance do
    desc "Analyze database performance and suggest optimizations"
    task analyze: :environment do
      puts "=== Database Performance Analysis ==="
      puts "Timestamp: #{Time.current}"
      puts
      
      # Check for unused indexes
      puts "🔍 Checking for unused indexes..."
      unused_indexes = ActiveRecord::Base.connection.execute(<<~SQL)
        SELECT schemaname, relname as tablename, indexrelname as indexname, idx_scan, idx_tup_read, idx_tup_fetch
        FROM pg_stat_user_indexes 
        WHERE idx_scan = 0 
        AND indexrelname NOT LIKE '%_pkey'
        ORDER BY relname, indexrelname
      SQL
      
      if unused_indexes.any?
        puts "❌ Unused indexes found:"
        unused_indexes.each do |idx|
          puts "  #{idx['indexname']} on #{idx['tablename']}"
        end
      else
        puts "✅ No unused indexes found"
      end
      puts
      
      # Check for missing indexes on foreign keys
      puts "🔍 Checking for missing foreign key indexes..."
      missing_fk_indexes = ActiveRecord::Base.connection.execute(<<~SQL)
        SELECT c.conrelid::regclass AS table_name,
               string_agg(a.attname, ', ') AS columns
        FROM pg_constraint c
        JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = ANY(c.conkey)
        WHERE c.contype = 'f'
        AND NOT EXISTS (
          SELECT 1 FROM pg_index i 
          WHERE i.indrelid = c.conrelid 
          AND i.indkey::int2[] @> c.conkey::int2[]
        )
        GROUP BY c.conrelid
        ORDER BY table_name
      SQL
      
      if missing_fk_indexes.any?
        puts "❌ Missing foreign key indexes:"
        missing_fk_indexes.each do |idx|
          puts "  #{idx['columns']} on #{idx['table_name']}"
        end
      else
        puts "✅ All foreign keys are properly indexed"
      end
      puts
      
      # Check index usage statistics
      puts "📊 Index usage statistics (top 10 most used):"
      index_stats = ActiveRecord::Base.connection.execute(<<~SQL)
        SELECT schemaname, relname as tablename, indexrelname as indexname, idx_scan, idx_tup_read, idx_tup_fetch
        FROM pg_stat_user_indexes 
        WHERE idx_scan > 0
        ORDER BY idx_scan DESC
        LIMIT 10
      SQL
      
      if index_stats.any?
        printf "%-40s %-20s %10s %12s %12s\n", "Index Name", "Table", "Scans", "Tuples Read", "Tuples Fetch"
        puts "-" * 95
        index_stats.each do |stat|
          printf "%-40s %-20s %10s %12s %12s\n", 
                 stat['indexname'], 
                 stat['tablename'], 
                 stat['idx_scan'], 
                 stat['idx_tup_read'], 
                 stat['idx_tup_fetch']
        end
      else
        puts "No index usage data available"
      end
      puts
      
      # Check table sizes
      puts "📊 Largest tables (top 10):"
      table_sizes = ActiveRecord::Base.connection.execute(<<~SQL)
        SELECT schemaname, tablename, 
               pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size,
               pg_total_relation_size(schemaname||'.'||tablename) as size_bytes
        FROM pg_tables 
        WHERE schemaname = 'public'
        ORDER BY size_bytes DESC
        LIMIT 10
      SQL
      
      if table_sizes.any?
        printf "%-30s %15s\n", "Table Name", "Size"
        puts "-" * 46
        table_sizes.each do |table|
          printf "%-30s %15s\n", table['tablename'], table['size']
        end
      end
      puts
    end
    
    desc "Update database statistics"
    task update_stats: :environment do
      puts "🔄 Updating database statistics..."
      start_time = Time.current
      
      ActiveRecord::Base.connection.execute("ANALYZE;")
      
      duration = Time.current - start_time
      puts "✅ Database statistics updated in #{duration.round(2)} seconds"
    end
    
    desc "Check for long-running queries"
    task check_long_queries: :environment do
      puts "🔍 Checking for long-running queries..."
      
      long_queries = ActiveRecord::Base.connection.execute(<<~SQL)
        SELECT pid, 
               now() - pg_stat_activity.query_start AS duration, 
               state,
               query 
        FROM pg_stat_activity 
        WHERE (now() - pg_stat_activity.query_start) > interval '5 minutes'
        AND state = 'active'
        AND query NOT LIKE '%pg_stat_activity%'
        ORDER BY duration DESC
      SQL
      
      if long_queries.any?
        puts "❌ Long-running queries detected:"
        long_queries.each do |query|
          puts "  PID: #{query['pid']}, Duration: #{query['duration']}, State: #{query['state']}"
          puts "  Query: #{query['query'][0..100]}..."
          puts
        end
      else
        puts "✅ No long-running queries detected"
      end
    end
    
    desc "Show connection pool statistics"
    task connection_pool: :environment do
      puts "📊 Connection Pool Statistics:"
      
      pool = ActiveRecord::Base.connection_pool
      puts "  Total connections: #{pool.size}"
      
      # Use stat method for Rails 7+ compatibility
      if pool.respond_to?(:stat)
        stat = pool.stat
        puts "  Active connections: #{stat[:busy]}"
        puts "  Available connections: #{stat[:size] - stat[:busy]}"
        puts "  Waiting: #{stat[:waiting]}"
        puts "  Utilization: #{((stat[:busy].to_f / stat[:size]) * 100).round(2)}%"
        
        if stat[:busy].to_f / stat[:size] > 0.8
          puts "⚠️  Warning: Connection pool utilization is high (>80%)"
        else
          puts "✅ Connection pool utilization is healthy"
        end
      else
        # Fallback for older Rails versions
        begin
          active_connections = pool.connections.count(&:in_use?)
          puts "  Active connections: #{active_connections}"
          puts "  Available connections: #{pool.size - active_connections}"
          puts "  Utilization: #{((active_connections.to_f / pool.size) * 100).round(2)}%"
          
          if active_connections.to_f / pool.size > 0.8
            puts "⚠️  Warning: Connection pool utilization is high (>80%)"
          else
            puts "✅ Connection pool utilization is healthy"
          end
        rescue => e
          puts "❌ Error retrieving connection pool stats: #{e.message}"
          puts "  Total connections: #{pool.size}"
        end
      end
    end
    
    desc "Show cache performance statistics"
    task cache_stats: :environment do
      puts "📊 Cache Performance Statistics:"
      
      begin
        if Rails.cache.respond_to?(:redis)
          redis_info = Rails.cache.redis.info
          hits = redis_info['keyspace_hits'].to_i
          misses = redis_info['keyspace_misses'].to_i
          total = hits + misses
          
          puts "  Total commands: #{redis_info['total_commands_processed']}"
          puts "  Memory usage: #{redis_info['used_memory_human']}"
          puts "  Connected clients: #{redis_info['connected_clients']}"
          
          if total > 0
            hit_rate = ((hits.to_f / total) * 100).round(2)
            puts "  Hit rate: #{hit_rate}%"
            
            if hit_rate < 85
              puts "⚠️  Warning: Cache hit rate is below 85%"
            else
              puts "✅ Cache hit rate is healthy"
            end
          else
            puts "  No cache statistics available yet"
          end
        else
          puts "❌ Redis cache not available"
        end
      rescue => e
        puts "❌ Error retrieving cache stats: #{e.message}"
      end
    end
    
    desc "Run comprehensive performance analysis"
    task full_analysis: :environment do
      puts "🚀 Running comprehensive database performance analysis..."
      puts "=" * 60
      puts
      
      Rake::Task['db:performance:analyze'].invoke
      puts
      Rake::Task['db:performance:check_long_queries'].invoke
      puts
      Rake::Task['db:performance:connection_pool'].invoke
      puts
      Rake::Task['db:performance:cache_stats'].invoke
      puts
      
      puts "=" * 60
      puts "✅ Performance analysis complete!"
      puts "💡 Tip: Run 'rails db:performance:update_stats' regularly to keep statistics current"
    end
  end
end
