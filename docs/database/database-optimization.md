# Database Optimization Plan

## Current State Analysis

### Database Architecture
- **Database**: PostgreSQL with Rails 7.1
- **Connection Pool**: 5 connections (configurable via `DB_POOL_SIZE`)
- **Statement Timeout**: 5 seconds
- **Caching Layer**: Redis with IdentityCache
- **Current Optimizations**: 
  - IdentityCache enabled for key models (Restaurant, Ordr, Menuitem)
  - Some eager loading with `includes` in controllers
  - Prepared statements enabled

### Identified Performance Issues

1. **N+1 Query Problems**
   - Multiple controllers showing N+1 patterns despite some `includes` usage
   - Complex association chains in menu/order operations
   - Localization queries not optimized

2. **Missing Database Indexes**
   - No comprehensive index strategy visible
   - Foreign key relationships may lack proper indexing
   - Composite indexes missing for common query patterns

3. **Inefficient Query Patterns**
   - Multiple separate queries in methods like `totalItemsCount`
   - Suboptimal joins in complex operations
   - No read replica strategy

4. **Cache Strategy Gaps**
   - IdentityCache only on select models
   - No application-level query result caching
   - Missing cache warming strategies

## Optimization Strategy

### Phase 1: Database Indexing & Query Optimization (Weeks 1-2)

#### 1.1 Database Index Audit & Implementation

**Priority: HIGH**

Create comprehensive indexing strategy:

```sql
-- Core business logic indexes
CREATE INDEX CONCURRENTLY idx_restaurants_user_id_status ON restaurants(user_id, status) WHERE archived = false;
CREATE INDEX CONCURRENTLY idx_menus_restaurant_id_status ON menus(restaurant_id, status) WHERE archived = false;
CREATE INDEX CONCURRENTLY idx_menuitems_menusection_id_status ON menuitems(menusection_id, status) WHERE archived = false;
CREATE INDEX CONCURRENTLY idx_ordrs_restaurant_id_status_created ON ordrs(restaurant_id, status, created_at);
CREATE INDEX CONCURRENTLY idx_ordritems_ordr_id_status ON ordritems(ordr_id, status);

-- Localization indexes
CREATE INDEX CONCURRENTLY idx_menuitemlocales_menuitem_locale ON menuitemlocales(menuitem_id, locale);
CREATE INDEX CONCURRENTLY idx_restaurantlocales_restaurant_locale ON restaurantlocales(restaurant_id, locale);
CREATE INDEX CONCURRENTLY idx_menusectionlocales_menusection_locale ON menusectionlocales(menusection_id, locale);

-- Association mapping indexes
CREATE INDEX CONCURRENTLY idx_menuitem_allergyn_mappings_menuitem ON menuitem_allergyn_mappings(menuitem_id);
CREATE INDEX CONCURRENTLY idx_menuitem_size_mappings_menuitem ON menuitem_size_mappings(menuitem_id);
CREATE INDEX CONCURRENTLY idx_menuitem_tag_mappings_menuitem ON menuitem_tag_mappings(menuitem_id);

-- Performance critical composite indexes
CREATE INDEX CONCURRENTLY idx_ordrs_tablesetting_status_created ON ordrs(tablesetting_id, status, created_at);
CREATE INDEX CONCURRENTLY idx_employees_restaurant_user_status ON employees(restaurant_id, user_id, status);
```

**Implementation Steps:**
1. Create migration files for each index
2. Use `CONCURRENTLY` to avoid locking
3. Monitor index usage with `pg_stat_user_indexes`
4. Remove unused indexes after monitoring period

#### 1.2 Query Optimization

**Priority: HIGH**

**Optimize N+1 Queries:**

```ruby
# app/models/concerns/optimized_queries.rb
module OptimizedQueries
  extend ActiveSupport::Concern
  
  class_methods do
    def with_full_associations
      includes(
        :restaurant,
        menus: [
          :menuavailabilities,
          menusections: [
            :menusectionlocales,
            menuitems: [
              :menuitemlocales,
              :allergyns,
              :sizes,
              :tags,
              :ingredients,
              :inventory,
              :genimage
            ]
          ]
        ]
      )
    end
  end
end
```

**Optimize Ordr Model Queries:**

```ruby
# app/models/ordr.rb - Replace inefficient methods
class Ordr < ApplicationRecord
  # Replace multiple separate queries with single optimized query
  def item_counts_optimized
    @item_counts ||= ordritems.group(:status).count
  end
  
  def ordered_items_count
    item_counts_optimized[20] || 0
  end
  
  def prepared_items_count  
    item_counts_optimized[30] || 0
  end
  
  def delivered_items_count
    item_counts_optimized[40] || 0
  end
  
  def total_items_count
    item_counts_optimized.values.sum
  end
  
  # Optimize running total calculation
  def running_total
    Rails.cache.fetch("ordr_#{id}_running_total", expires_in: 5.minutes) do
      ordritems.sum(:ordritemprice)
    end
  end
end
```

#### 1.3 Database Configuration Optimization

**Priority: MEDIUM**

```yaml
# config/database.yml - Production optimizations
production:
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("DB_POOL_SIZE", 25).to_i %>
  checkout_timeout: 30
  prepared_statements: true
  variables:
    statement_timeout: 30000  # 30 seconds for complex queries
    lock_timeout: 10000       # 10 seconds
    idle_in_transaction_session_timeout: 60000  # 1 minute
  reaping_frequency: 10
  dead_connection_timeout: 30
```

### Phase 2: Read Replica Implementation (Weeks 3-4)

#### 2.1 Read Replica Configuration

**Priority: HIGH**

**Database Configuration:**

```ruby
# config/database.yml
production:
  primary:
    adapter: postgresql
    encoding: unicode
    database: smart_menu_production
    username: smart_menu
    password: <%= ENV["SMART_MENU_DATABASE_PASSWORD"] %>
    pool: <%= ENV.fetch("DB_POOL_SIZE", 5).to_i %>
    
  primary_replica:
    adapter: postgresql
    encoding: unicode
    database: smart_menu_production
    username: smart_menu_readonly
    password: <%= ENV["SMART_MENU_REPLICA_PASSWORD"] %>
    host: <%= ENV["SMART_MENU_REPLICA_HOST"] %>
    replica: true
    pool: <%= ENV.fetch("DB_POOL_SIZE", 5).to_i %>
```

**Application Configuration:**

```ruby
# config/application.rb
class Application < Rails::Application
  config.active_record.database_selector = { delay: 2.seconds }
  config.active_record.database_resolver = ActiveRecord::Middleware::DatabaseSelector::Resolver
  config.active_record.database_resolver_context = ActiveRecord::Middleware::DatabaseSelector::Resolver::Session
end
```

#### 2.2 Read/Write Splitting Strategy

**Priority: HIGH**

**Implement Read Replica Routing:**

```ruby
# app/models/concerns/read_replica_routing.rb
module ReadReplicaRouting
  extend ActiveSupport::Concern
  
  class_methods do
    def from_replica
      connected_to(role: :reading) { yield }
    end
    
    def analytics_queries
      from_replica do
        yield
      end
    end
  end
end

# Usage in controllers
class MetricsController < ApplicationController
  def index
    @metrics = Restaurant.analytics_queries do
      Restaurant.joins(:ordrs)
               .where(ordrs: { created_at: 1.month.ago.. })
               .group(:name)
               .count
    end
  end
end
```

**Automatic Read Replica Selection:**

```ruby
# app/controllers/concerns/database_routing.rb
module DatabaseRouting
  extend ActiveSupport::Concern
  
  included do
    around_action :route_database_queries
  end
  
  private
  
  def route_database_queries
    if read_only_action?
      ActiveRecord::Base.connected_to(role: :reading) { yield }
    else
      yield
    end
  end
  
  def read_only_action?
    request.get? && !params[:force_primary]
  end
end
```

### Phase 3: Advanced Caching Strategy (Weeks 5-6)

#### 3.1 Expand IdentityCache Usage

**Priority: HIGH**

**Implement IdentityCache on All Core Models:**

```ruby
# app/models/menu.rb
class Menu < ApplicationRecord
  include IdentityCache
  
  cache_index :id
  cache_index :restaurant_id
  cache_index [:restaurant_id, :status], unique: false
  
  cache_has_many :menusections, embed: :ids
  cache_has_many :menuavailabilities, embed: :ids
  cache_belongs_to :restaurant
end

# app/models/menuitem.rb  
class Menuitem < ApplicationRecord
  include IdentityCache
  
  cache_index :id
  cache_index :menusection_id
  cache_index [:menusection_id, :status], unique: false
  
  cache_has_many :allergyns, embed: :ids
  cache_has_many :sizes, embed: :ids
  cache_has_many :tags, embed: :ids
  cache_belongs_to :menusection
end
```

#### 3.2 Application-Level Query Caching

**Priority: MEDIUM**

**Implement Smart Query Caching:**

```ruby
# app/services/query_cache_service.rb
class QueryCacheService
  CACHE_DURATIONS = {
    restaurant_menu: 1.hour,
    menu_items: 30.minutes,
    order_analytics: 15.minutes,
    user_preferences: 1.day
  }.freeze
  
  def self.cached_restaurant_menu(restaurant_id, locale = 'en')
    Rails.cache.fetch(
      "restaurant_menu:#{restaurant_id}:#{locale}",
      expires_in: CACHE_DURATIONS[:restaurant_menu]
    ) do
      Restaurant.find(restaurant_id)
                .menus
                .active
                .includes(
                  menusections: [
                    :menusectionlocales,
                    menuitems: [:menuitemlocales, :allergyns, :sizes]
                  ]
                )
    end
  end
  
  def self.cached_order_analytics(restaurant_id, date_range)
    cache_key = "order_analytics:#{restaurant_id}:#{date_range.hash}"
    
    Rails.cache.fetch(cache_key, expires_in: CACHE_DURATIONS[:order_analytics]) do
      Restaurant.analytics_queries do
        Ordr.joins(:restaurant)
            .where(restaurant_id: restaurant_id, created_at: date_range)
            .group_by_day(:created_at)
            .count
      end
    end
  end
end
```

#### 3.3 Cache Warming Strategy

**Priority: MEDIUM**

**Implement Cache Warming Jobs:**

```ruby
# app/jobs/cache_warming_job.rb
class CacheWarmingJob < ApplicationJob
  queue_as :low_priority
  
  def perform(restaurant_id)
    restaurant = Restaurant.find(restaurant_id)
    
    # Warm IdentityCache
    Restaurant.fetch(restaurant_id)
    restaurant.menus.each { |menu| Menu.fetch(menu.id) }
    
    # Warm application cache
    restaurant.restaurantlocales.pluck(:locale).each do |locale|
      QueryCacheService.cached_restaurant_menu(restaurant_id, locale)
    end
    
    # Warm analytics cache
    QueryCacheService.cached_order_analytics(
      restaurant_id, 
      30.days.ago..Time.current
    )
  end
end

# Schedule cache warming
# config/schedule.rb (using whenever gem)
every 1.hour do
  runner "Restaurant.active.find_each { |r| CacheWarmingJob.perform_later(r.id) }"
end
```

### Phase 4: Connection Pool & Performance Monitoring (Week 7)

#### 4.1 Connection Pool Optimization

**Priority: MEDIUM**

**Dynamic Connection Pool Sizing:**

```ruby
# config/initializers/database_pool.rb
Rails.application.configure do
  # Calculate optimal pool size based on server capacity
  cpu_count = Etc.nprocessors
  base_pool_size = ENV.fetch("DB_POOL_SIZE", cpu_count * 2).to_i
  
  # Adjust based on environment
  pool_size = case Rails.env
              when 'production'
                [base_pool_size, 50].min  # Cap at 50 connections
              when 'staging'
                [base_pool_size, 25].min
              else
                5
              end
  
  config.active_record.connection_pool_size = pool_size
end
```

#### 4.2 Database Performance Monitoring

**Priority: HIGH**

**Implement Query Performance Monitoring:**

```ruby
# app/middleware/database_performance_middleware.rb
class DatabasePerformanceMiddleware
  def initialize(app)
    @app = app
  end
  
  def call(env)
    query_count = 0
    query_time = 0
    
    subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*args|
      event = ActiveSupport::Notifications::Event.new(*args)
      query_count += 1
      query_time += event.duration
    end
    
    response = @app.call(env)
    
    # Log slow requests
    if query_time > 1000 || query_count > 50
      Rails.logger.warn(
        "Slow database performance: #{query_count} queries in #{query_time.round(2)}ms"
      )
    end
    
    response
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
  end
end
```

**Add Database Metrics to Health Checks:**

```ruby
# app/controllers/health_controller.rb - Add to existing controller
def database_performance
  start_time = Time.current
  
  # Test query performance
  simple_query_time = Benchmark.realtime do
    ActiveRecord::Base.connection.execute('SELECT 1')
  end
  
  complex_query_time = Benchmark.realtime do
    Restaurant.joins(:menus).limit(10).count
  end
  
  # Check connection pool
  pool = ActiveRecord::Base.connection_pool
  pool_stats = {
    size: pool.size,
    checked_out: pool.checked_out.size,
    available: pool.available_connections.size
  }
  
  render json: {
    status: 'healthy',
    simple_query_ms: (simple_query_time * 1000).round(2),
    complex_query_ms: (complex_query_time * 1000).round(2),
    connection_pool: pool_stats,
    timestamp: Time.current.iso8601
  }
end
```

### Phase 5: Database Maintenance & Monitoring (Week 8)

#### 5.1 Automated Database Maintenance

**Priority: MEDIUM**

**Database Maintenance Tasks:**

```ruby
# lib/tasks/database_maintenance.rake
namespace :db do
  desc "Analyze database performance and suggest optimizations"
  task analyze_performance: :environment do
    puts "=== Database Performance Analysis ==="
    
    # Check for unused indexes
    unused_indexes = ActiveRecord::Base.connection.execute(<<~SQL)
      SELECT schemaname, tablename, indexname, idx_scan
      FROM pg_stat_user_indexes 
      WHERE idx_scan = 0 
      AND indexname NOT LIKE '%_pkey'
    SQL
    
    puts "Unused indexes:"
    unused_indexes.each { |idx| puts "  #{idx['indexname']} on #{idx['tablename']}" }
    
    # Check for missing indexes on foreign keys
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
    SQL
    
    puts "Missing foreign key indexes:"
    missing_fk_indexes.each { |idx| puts "  #{idx['columns']} on #{idx['table_name']}" }
  end
  
  desc "Update database statistics"
  task update_stats: :environment do
    ActiveRecord::Base.connection.execute("ANALYZE;")
    puts "Database statistics updated"
  end
  
  desc "Check for long-running queries"
  task check_long_queries: :environment do
    long_queries = ActiveRecord::Base.connection.execute(<<~SQL)
      SELECT pid, now() - pg_stat_activity.query_start AS duration, query 
      FROM pg_stat_activity 
      WHERE (now() - pg_stat_activity.query_start) > interval '5 minutes'
      AND state = 'active'
    SQL
    
    if long_queries.any?
      puts "Long-running queries detected:"
      long_queries.each do |query|
        puts "  PID: #{query['pid']}, Duration: #{query['duration']}"
        puts "  Query: #{query['query'][0..100]}..."
      end
    else
      puts "No long-running queries detected"
    end
  end
end
```

#### 5.2 Performance Monitoring Dashboard

**Priority: LOW**

**Add Database Metrics to Existing Metrics System:**

```ruby
# app/controllers/metrics_controller.rb - Enhance existing controller
def database_metrics
  authorize :metric, :show?
  
  @database_metrics = {
    connection_pool: connection_pool_stats,
    query_performance: recent_query_performance,
    cache_hit_rates: cache_performance_stats,
    slow_queries: slow_query_analysis
  }
end

private

def connection_pool_stats
  pool = ActiveRecord::Base.connection_pool
  {
    total_connections: pool.size,
    active_connections: pool.checked_out.size,
    available_connections: pool.available_connections.size,
    utilization_percent: ((pool.checked_out.size.to_f / pool.size) * 100).round(2)
  }
end

def cache_performance_stats
  if Rails.cache.respond_to?(:redis)
    redis_info = Rails.cache.redis.info
    hits = redis_info['keyspace_hits'].to_i
    misses = redis_info['keyspace_misses'].to_i
    total = hits + misses
    
    {
      hit_rate: total > 0 ? ((hits.to_f / total) * 100).round(2) : 0,
      total_commands: redis_info['total_commands_processed'],
      memory_usage: redis_info['used_memory_human']
    }
  else
    { error: 'Redis not available' }
  end
end
```

## Implementation Timeline

### Week 1-2: Foundation (Database Indexing)
- [ ] Create database index audit
- [ ] Implement core business logic indexes
- [ ] Add localization indexes  
- [ ] Create association mapping indexes
- [ ] Monitor index usage

### Week 3-4: Read Replicas
- [ ] Set up read replica infrastructure
- [ ] Configure database.yml for read/write splitting
- [ ] Implement read replica routing middleware
- [ ] Test read replica functionality
- [ ] Monitor replication lag

### Week 5-6: Advanced Caching
- [ ] Expand IdentityCache to all core models
- [ ] Implement QueryCacheService
- [ ] Create cache warming jobs
- [ ] Set up cache invalidation strategies
- [ ] Monitor cache hit rates

### Week 7: Connection Pool & Monitoring
- [ ] Optimize connection pool configuration
- [ ] Implement database performance middleware
- [ ] Add database metrics to health checks
- [ ] Set up performance alerting
- [ ] Load test optimizations

### Week 8: Maintenance & Documentation
- [ ] Create database maintenance tasks
- [ ] Set up automated performance monitoring
- [ ] Document optimization strategies
- [ ] Create runbooks for database issues
- [ ] Train team on new tools

## Success Metrics

### Performance Targets
- **Query Response Time**: < 100ms for 95% of queries
- **Page Load Time**: < 500ms for menu pages
- **Database Connection Pool**: < 70% utilization
- **Cache Hit Rate**: > 85% for IdentityCache
- **N+1 Queries**: Zero in critical paths

### Monitoring KPIs
- Average query execution time
- Database connection pool utilization
- Cache hit/miss ratios
- Slow query frequency
- Replication lag (when implemented)

## Risk Mitigation

### High-Risk Items
1. **Read Replica Lag**: Monitor replication lag, implement fallback to primary
2. **Cache Invalidation**: Careful cache key design, implement cache warming
3. **Index Lock Contention**: Use CONCURRENTLY for index creation
4. **Connection Pool Exhaustion**: Gradual pool size increases with monitoring

### Rollback Plans
- Database indexes can be dropped if causing issues
- Read replica can be disabled via configuration
- Cache layers can be bypassed with feature flags
- Connection pool changes are easily reversible

## Tools & Resources

### Required Gems
```ruby
# Add to Gemfile
gem 'pg_query'           # Query analysis
gem 'marginalia'         # Query commenting
gem 'bullet'             # N+1 detection (already installed)
gem 'rack-mini-profiler' # Performance profiling
```

### PostgreSQL Extensions
```sql
-- Enable useful extensions
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
CREATE EXTENSION IF NOT EXISTS pg_buffercache;
```

### Monitoring Tools
- **Database**: pg_stat_statements, pgBadger
- **Application**: Rails built-in query logs, Bullet gem
- **Cache**: Redis INFO command, custom metrics
- **Infrastructure**: Database connection monitoring

This comprehensive plan addresses the current database performance issues while providing a clear roadmap for implementation and monitoring.
