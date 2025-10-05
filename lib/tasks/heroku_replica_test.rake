namespace :heroku do
  namespace :replica do
    desc "Test read replica configuration on Heroku"
    task test: :environment do
      puts "🔍 Testing Heroku Read Replica Configuration"
      puts "=" * 50
      
      begin
        # Test primary connection
        puts "\n🔵 Testing Primary Database Connection:"
        ApplicationRecord.on_primary do
          result = ApplicationRecord.connection.execute("SELECT 'Primary connection successful' as status, now() as timestamp")
          puts "  ✅ Primary: #{result.first['status']} at #{result.first['timestamp']}"
          puts "  📍 Host: #{ApplicationRecord.connection.instance_variable_get(:@connection).host}"
          puts "  🗄️  Database: #{ApplicationRecord.connection.current_database}"
        end
        
        # Test replica connection
        puts "\n🟢 Testing Replica Database Connection:"
        ApplicationRecord.on_replica do
          result = ApplicationRecord.connection.execute("SELECT 'Replica connection successful' as status, now() as timestamp")
          puts "  ✅ Replica: #{result.first['status']} at #{result.first['timestamp']}"
          puts "  📍 Host: #{ApplicationRecord.connection.instance_variable_get(:@connection).host}"
          puts "  🗄️  Database: #{ApplicationRecord.connection.current_database}"
        end
        
        # Test routing service
        puts "\n🔄 Testing Database Routing Service:"
        if defined?(DatabaseRoutingService)
          stats = DatabaseRoutingService.connection_stats
          puts "  📊 Primary Pool: #{stats[:primary][:busy]}/#{stats[:primary][:size]} connections"
          puts "  📊 Replica Pool: #{stats[:replica][:busy]}/#{stats[:replica][:size]} connections" if stats[:replica]
          puts "  🏥 Replica Healthy: #{stats[:replica_healthy] ? '✅ Yes' : '❌ No'}"
          puts "  ⏱️  Replica Lag: #{stats[:replica_lag].round(3)}s" if stats[:replica_lag] != Float::INFINITY
        end
        
        # Test analytics service
        puts "\n📊 Testing Analytics Service:"
        if defined?(AnalyticsReportingService) && Restaurant.exists?
          restaurant = Restaurant.first
          DatabaseRoutingService.with_analytics_connection do
            count = restaurant.ordrs.count
            puts "  ✅ Analytics query successful: #{count} orders found for #{restaurant.name}"
            puts "  🔗 Connection: #{ApplicationRecord.using_replica? ? 'Replica' : 'Primary'}"
          end
        else
          puts "  ⚠️  No restaurants found for analytics test"
        end
        
        puts "\n🎉 All tests passed! Read replica is configured correctly."
        
      rescue => e
        puts "\n❌ Error testing replica configuration: #{e.message}"
        puts "   #{e.backtrace.first}"
        
        # Fallback test
        puts "\n🔄 Testing fallback to primary..."
        begin
          ApplicationRecord.on_primary do
            result = ApplicationRecord.connection.execute("SELECT 'Fallback successful' as status")
            puts "  ✅ Fallback: #{result.first['status']}"
          end
        rescue => fallback_error
          puts "  ❌ Fallback failed: #{fallback_error.message}"
        end
      end
    end
    
    desc "Show Heroku database information"
    task info: :environment do
      puts "🗄️  Heroku Database Information"
      puts "=" * 40
      
      # Show environment variables
      puts "\n📝 Environment Variables:"
      puts "  DATABASE_URL: #{ENV['DATABASE_URL'] ? '✅ Set' : '❌ Not set'}"
      puts "  REPLICA_DATABASE_URL: #{ENV['REPLICA_DATABASE_URL'] ? '✅ Set' : '❌ Not set'}"
      puts "  REPLICA_DB_POOL_SIZE: #{ENV['REPLICA_DB_POOL_SIZE'] || 'Default (15)'}"
      
      # Show database configurations
      puts "\n⚙️  Database Configurations:"
      config = Rails.application.config.database_configuration['production']
      if config
        puts "  Primary URL: #{config['primary']['url'] ? '✅ Configured' : '❌ Not configured'}"
        puts "  Replica URL: #{config['replica']['url'] ? '✅ Configured' : '❌ Not configured'}"
        puts "  Replica Pool: #{config['replica']['pool'] || 'Default'}"
      end
      
      # Show connection pool status
      puts "\n🏊 Connection Pool Status:"
      begin
        if defined?(DatabaseRoutingService)
          stats = DatabaseRoutingService.connection_stats
          puts "  Primary: #{stats[:primary][:utilization]}% utilization" if stats[:primary]
          puts "  Replica: #{stats[:replica][:utilization]}% utilization" if stats[:replica]
        end
      rescue => e
        puts "  ❌ Unable to get pool stats: #{e.message}"
      end
    end
  end
end
