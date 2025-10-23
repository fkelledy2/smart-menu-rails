# Load Test Optimization Guide

## 📊 Current Status

**Peak Hour Test Results**:
- ✅ Test running successfully with 500 concurrent users
- ✅ Order validation working (422 responses)
- 🟡 Menu browse: 2.1-2.8s (target: < 2s)
- ✅ **40-50% improvement** from initial 4.8s!

## 🎯 Remaining Performance Gap

| Metric | Before | Current | Target | Gap |
|--------|--------|---------|--------|-----|
| Menu Load (p95) | 4.81s | 2.1-2.8s | < 2s | 0.1-0.8s |
| Improvement | - | 42-56% | 58%+ | Need 5-40% more |

## 🔍 Bottleneck Analysis

### Already Fixed ✅
1. **SmartMenu N+1 queries** - Comprehensive eager loading implemented
2. **HTTP caching** - ETags added for repeat visits

### Remaining Issues 🟡

#### 1. **Database Connection Pool Too Small**
```yaml
# config/database.yml
development:
  pool: 5  # ← TOO SMALL for load testing
```

**Problem**: With 10-100 concurrent users, 5 connections is insufficient
- Requests queue waiting for connections
- Adds 100-500ms latency per request

**Solution**: Increase pool size for development load testing

#### 2. **View Rendering Overhead**
- HTML rendering takes time even with eager-loaded data
- No fragment caching in views
- Large HTML payloads

#### 3. **Asset Loading**
- JavaScript bundles may be large
- No CDN in development
- Images not optimized

#### 4. **Server Resources**
- Single Puma worker in development
- Limited CPU/memory for high concurrency

## 🔧 Quick Fixes (Do Now)

### 1. Increase Database Pool for Load Testing

Create a temporary configuration for load testing:

```bash
# Set environment variable before running load test
export DB_POOL_SIZE=25

# Then run your Rails server
bin/rails server
```

Or modify `config/database.yml` temporarily:

```yaml
development:
  primary:
    <<: *default
    database: smart_menu_development
    pool: <%= ENV.fetch("DB_POOL_SIZE", 25).to_i %>  # Increased from 5
```

**Expected Impact**: 200-500ms improvement

### 2. Enable Development Caching

```bash
# Enable caching in development
bin/rails dev:cache

# Verify it's enabled
cat tmp/caching-dev.txt
# Should output: "yes"
```

**Expected Impact**: 50-80% improvement on repeat requests

### 3. Increase Puma Workers (Optional)

```ruby
# config/puma.rb
workers ENV.fetch("WEB_CONCURRENCY") { 2 }  # Add workers for load testing
threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
threads threads_count, threads_count
```

Then restart with:
```bash
WEB_CONCURRENCY=2 RAILS_MAX_THREADS=10 bin/rails server
```

**Expected Impact**: Better handling of concurrent requests

## 📈 Medium-Term Optimizations

### 1. Add Fragment Caching to Views

**SmartMenu Show View**:
```erb
<!-- app/views/smartmenus/show.html.erb -->
<% cache [@smartmenu, @menu, @restaurant] do %>
  <%= render partial: "smartmenus/showMenuBanner" %>
<% end %>

<% cache [@smartmenu, @menu, @allergyns.maximum(:updated_at)] do %>
  <% if current_user %>
    <%= render partial: "smartmenus/showMenuContentStaff", ... %>
  <% else %>
    <%= render partial: "smartmenus/showMenuContentCustomer", ... %>
  <% end %>
<% end %>
```

**Expected Impact**: 60-80% improvement on cached requests

### 2. Add Database Indexes

Check for missing indexes:

```bash
# Run this in Rails console
bin/rails console

# Check for missing indexes
ActiveRecord::Base.connection.tables.each do |table|
  puts "\n#{table}:"
  ActiveRecord::Base.connection.columns(table).select { |c| c.name.end_with?('_id') }.each do |column|
    indexes = ActiveRecord::Base.connection.indexes(table).select { |i| i.columns.include?(column.name) }
    puts "  #{column.name}: #{indexes.any? ? '✓' : '✗ MISSING'}"
  end
end
```

Add missing indexes in a migration:

```ruby
class AddMissingIndexes < ActiveRecord::Migration[7.0]
  def change
    # Add indexes for foreign keys if missing
    add_index :menuitems, :menusection_id unless index_exists?(:menuitems, :menusection_id)
    add_index :menusections, :menu_id unless index_exists?(:menusections, :menu_id)
    add_index :menuitemlocales, :menuitem_id unless index_exists?(:menuitemlocales, :menuitem_id)
    # ... add others as needed
  end
end
```

**Expected Impact**: 20-40% improvement on complex queries

### 3. Optimize View Partials

**Reduce Database Calls in Views**:
```erb
<!-- Instead of: -->
<% @menu.menusections.each do |section| %>
  <% section.menuitems.each do |item| %>
    <%= item.allergyns.map(&:name).join(', ') %>  <!-- N+1 query -->
  <% end %>
<% end %>

<!-- Use: -->
<% @menu.menusections.each do |section| %>
  <% section.menuitems.each do |item| %>
    <%= item.allergyns.pluck(:name).join(', ') %>  <!-- Single query -->
  <% end %>
<% end %>
```

## 🚀 Long-Term Optimizations

### 1. Implement Redis Caching

```ruby
# config/environments/development.rb
config.cache_store = :redis_cache_store, {
  url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/1'),
  expires_in: 1.hour
}
```

### 2. Add CDN for Assets

Use CloudFlare, Fastly, or AWS CloudFront for:
- JavaScript bundles
- CSS files
- Images
- Fonts

### 3. Implement GraphQL or JSON API

For mobile/SPA clients, reduce payload size:
- Only send requested fields
- Reduce over-fetching
- Enable client-side caching

### 4. Database Query Optimization

```ruby
# Use select to limit columns
@menu = Menu.select(:id, :name, :status, :updated_at)
            .includes(...)
            .find(params[:id])

# Use counter caches
class Menu < ApplicationRecord
  has_many :menusections
  # Add counter_cache: true
end

# Add column: menusections_count to menus table
```

## 📊 Testing Strategy

### Before Each Optimization

1. **Baseline measurement**:
   ```bash
   k6 run test/load/baseline_test.js > before.txt
   ```

2. **Apply optimization**

3. **Measure again**:
   ```bash
   k6 run test/load/baseline_test.js > after.txt
   ```

4. **Compare**:
   ```bash
   diff before.txt after.txt
   ```

### Expected Results After Quick Fixes

| Metric | Current | After Quick Fixes | Target |
|--------|---------|-------------------|--------|
| Menu Load (avg) | 2.1-2.8s | 800ms-1.2s | < 1s |
| Menu Load (p95) | 2.1-2.8s | 1.2-1.8s | < 2s |
| Checks Passed | ~85% | 90-95% | > 95% |

### Expected Results After Medium-Term Fixes

| Metric | Current | After All Fixes | Target |
|--------|---------|-----------------|--------|
| Menu Load (avg) | 2.1-2.8s | 200-400ms | < 500ms |
| Menu Load (p95) | 2.1-2.8s | 500-800ms | < 1s |
| Checks Passed | ~85% | 98%+ | > 95% |

## 🎯 Recommended Action Plan

### Phase 1: Quick Wins (Today) ⚡

1. **Increase DB pool size**:
   ```bash
   export DB_POOL_SIZE=25
   bin/rails server
   ```

2. **Enable development caching**:
   ```bash
   bin/rails dev:cache
   ```

3. **Re-run load test**:
   ```bash
   k6 run test/load/baseline_test.js
   ```

**Expected**: 30-50% improvement, bringing you to or below 2s target

### Phase 2: Fragment Caching (This Week) 📦

1. Add fragment caching to smartmenu views
2. Add fragment caching to menu partials
3. Test cache invalidation
4. Re-run load test

**Expected**: 60-80% improvement on repeat visits

### Phase 3: Database Optimization (This Month) 🗄️

1. Audit and add missing indexes
2. Optimize complex queries
3. Add counter caches where appropriate
4. Re-run load test

**Expected**: 20-40% improvement on database-heavy operations

## 📝 Monitoring Checklist

### During Load Test

Watch for:
- [ ] Database connection pool exhaustion
- [ ] Memory usage spikes
- [ ] CPU saturation
- [ ] Slow query logs
- [ ] Error rate increases

### Commands

```bash
# Watch database connections
watch -n 1 'psql -U your_user -d smart_menu_development -c "SELECT count(*) FROM pg_stat_activity WHERE datname = '\''smart_menu_development'\'';"'

# Watch memory
watch -n 1 'ps aux | grep puma'

# Watch slow queries in Rails logs
tail -f log/development.log | grep "Slow request"
```

## 🎉 Success Criteria

### Minimum (Phase 1)
- [x] SmartMenu optimization implemented
- [ ] DB pool increased
- [ ] Development caching enabled
- [ ] Menu load p95 < 2s
- [ ] Checks pass > 90%

### Target (Phase 2)
- [ ] Fragment caching implemented
- [ ] Menu load p95 < 1s
- [ ] Checks pass > 95%
- [ ] Cache hit rate > 80%

### Optimal (Phase 3)
- [ ] All indexes optimized
- [ ] Menu load p95 < 500ms
- [ ] Checks pass > 98%
- [ ] Cache hit rate > 95%

---

**Current Status**: Phase 1 (40-50% complete)  
**Next Step**: Increase DB pool size and enable caching  
**Expected Time to Target**: 1-2 hours for Phase 1
