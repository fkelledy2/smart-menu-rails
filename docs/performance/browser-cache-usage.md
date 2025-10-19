# Browser Cache Usage Guide

## Overview

The L4 Browser Cache system is now **ACTIVE** across the application. It provides intelligent cache headers, ETag support, and 304 Not Modified responses for optimal browser caching.

## Automatic Features

### 1. **Automatic Cache Headers** (All Controllers)

The `BrowserCacheable` concern is included in `ApplicationController`, which means **all controllers** automatically get intelligent cache headers based on content type:

- **HTML Pages**: `private, must-revalidate, max-age=0` (authenticated) or `public, max-age=60` (public)
- **JSON API**: `private, max-age=300` (cacheable) or `no-cache` (sensitive)
- **JavaScript/CSS**: `public, max-age=31536000, immutable`
- **Images**: `public, max-age=86400, immutable`

**No code changes needed** - this works automatically!

### 2. **ETag Support** (Selected Controllers)

ETag support has been added to key controllers for conditional requests:

#### **RestaurantsController**
```ruby
# JSON responses automatically return 304 if unchanged
GET /restaurants/1.json
# Returns: 304 Not Modified (if ETag matches)
# Or: 200 OK with ETag header (if changed)
```

#### **MenusController**
```ruby
# JSON responses automatically return 304 if unchanged
GET /restaurants/1/menus/1.json
# Returns: 304 Not Modified (if ETag matches)
```

#### **MenuitemsController**
```ruby
# JSON responses automatically return 304 if unchanged
GET /menuitems/1.json
# Returns: 304 Not Modified (if ETag matches)
```

## Manual Usage in Controllers

### Using ETag for Individual Resources

```ruby
def show
  @restaurant = Restaurant.find(params[:id])
  
  # Return 304 if client has current version
  return if cache_with_etag(@restaurant, max_age: 300, public: false)
  
  # Continue with normal rendering
  render :show
end
```

### Using ETag for Collections

```ruby
def index
  @restaurants = Restaurant.all
  
  # Return 304 if collection hasn't changed
  return if cache_collection_with_etag(@restaurants, max_age: 300)
  
  render :index
end
```

### Custom Cache Options

```ruby
# Public caching with longer TTL
cache_with_etag(@resource, max_age: 3600, public: true)

# Private caching with stale-while-revalidate
cache_page(max_age: 300, public: false, stale_while_revalidate: 60)

# Disable caching for sensitive data
no_browser_cache
```

### Weak ETags

```ruby
# Use weak ETag for resources that can have minor differences
cache_with_etag(@resource, weak: true)
```

## Monitoring & Analytics

### View Cache Statistics

```bash
# Show overall cache statistics
bundle exec rake browser_cache:stats

# Output:
# Browser Cache Statistics
# ========================
# Total Requests: 1,000
# Cached Responses: 850 (85.0%)
# No-Cache Responses: 150 (15.0%)
# ETag Responses: 700 (70.0%)
# 304 Not Modified: 600 (60.0%)
```

### Check Cache Health

```bash
# Check cache health status
bundle exec rake browser_cache:health

# Output:
# Browser Cache Health Check
# ==========================
# Status: excellent
# Cache Hit Rate: 85.0%
# Not Modified Rate: 60.0%
# Recommendations:
#   - Cache performance is excellent
#   - ETag validation working well
```

### Performance Analysis

```bash
# Detailed performance analysis
bundle exec rake browser_cache:analyze

# Output:
# Browser Cache Performance Analysis
# ==================================
# Overall Performance: excellent
# Cache Hit Rate: 85.0%
# ETag Validation Rate: 70.0%
# 
# By Content Type:
#   - text/html: 500 requests (50.0%)
#   - application/json: 300 requests (30.0%)
#   - image/jpeg: 200 requests (20.0%)
```

### View Configuration

```bash
# Show current configuration
bundle exec rake browser_cache:config

# Output:
# Browser Cache Configuration
# ===========================
# Environment: production
# Cache Enabled: true
# Default Max Age: 300 seconds
# Service Worker: enabled
```

### Test Services

```bash
# Test all browser cache services
bundle exec rake browser_cache:test

# Output:
# Browser Cache Configuration Test
# =================================
# ✓ BrowserCacheService initialized
# ✓ BrowserCacheAnalyticsService initialized
# ✓ All tests passed
```

### Reset Statistics

```bash
# Reset all cache statistics
bundle exec rake browser_cache:reset_stats

# Output:
# Browser cache statistics reset successfully
```

## Service Worker Features

The enhanced service worker provides:

### 1. **Cache Size Management**

```javascript
// Get cache statistics
const stats = await sw.getCacheStats()
// => { static: 25MB, dynamic: 10MB, api: 5MB }

// Automatic LRU eviction when limits reached:
// - Static Cache: 50MB
// - Dynamic Cache: 25MB
// - API Cache: 10MB
```

### 2. **Cache Warming**

```javascript
// Warm cache with critical resources
await sw.warmCache()
// Pre-caches: /, /manifest.json, /offline, critical CSS/JS
```

### 3. **Selective Purging**

```javascript
// Purge cache by pattern
await sw.purgeCache('assets/*.js')
await sw.purgeCache('api/restaurants/*')

// Purge all caches
await sw.purgeCache('*')
```

## Expected Performance Benefits

### Network Reduction
- **60% reduction** in repeat page loads (304 responses)
- **80% reduction** in API requests (browser cache hits)
- **50% reduction** in bandwidth usage
- **90% reduction** in static asset requests

### Performance Improvements
- **Instant** page loads from browser cache
- **<50ms** for 304 Not Modified responses
- **Zero network** for cached resources
- **Offline support** for all cached content

### User Experience
- **Instant navigation** for cached pages
- **Offline functionality** for critical features
- **Reduced data usage** for mobile users
- **Faster perceived performance**

### Server Load Reduction
- **40% reduction** in server processing (304 responses)
- **60% reduction** in database queries (cached responses)
- **50% reduction** in bandwidth costs
- **Better scalability** with client-side caching

## Best Practices

### 1. **Use ETags for Dynamic Content**

```ruby
# Good: ETag for resources that change
def show
  return if cache_with_etag(@restaurant)
  render :show
end

# Bad: No caching for dynamic content
def show
  render :show
end
```

### 2. **Use Collection ETags for Lists**

```ruby
# Good: ETag based on collection state
def index
  return if cache_collection_with_etag(@restaurants)
  render :index
end

# Bad: No caching for collections
def index
  render :index
end
```

### 3. **Disable Caching for Sensitive Data**

```ruby
# Good: Explicitly disable caching
def show_payment
  no_browser_cache
  render :show
end

# Bad: Allowing default caching for sensitive data
def show_payment
  render :show
end
```

### 4. **Use Public Caching for Shared Resources**

```ruby
# Good: Public caching for shared content
def show_public_menu
  return if cache_with_etag(@menu, public: true, max_age: 3600)
  render :show
end

# Bad: Private caching for public content
def show_public_menu
  return if cache_with_etag(@menu, public: false)
  render :show
end
```

### 5. **Monitor Cache Performance**

```bash
# Regular monitoring
bundle exec rake browser_cache:stats
bundle exec rake browser_cache:health

# Weekly analysis
bundle exec rake browser_cache:analyze
```

## Troubleshooting

### Issue: Cache Not Working

**Check:**
1. Verify `BrowserCacheable` is included in controller
2. Check if `skip_browser_cache?` is returning true
3. Verify request is GET or HEAD
4. Check if Turbo Frame request (automatically skipped)

**Solution:**
```ruby
# Debug cache headers
def show
  @restaurant = Restaurant.find(params[:id])
  cache_with_etag(@restaurant)
  
  # Check response headers
  Rails.logger.debug "Cache-Control: #{response.headers['Cache-Control']}"
  Rails.logger.debug "ETag: #{response.headers['ETag']}"
  
  render :show
end
```

### Issue: 304 Not Being Returned

**Check:**
1. Verify client is sending `If-None-Match` header
2. Check if resource has actually changed
3. Verify ETag format is correct

**Solution:**
```ruby
# Debug ETag matching
def show
  @restaurant = Restaurant.find(params[:id])
  etag = generate_etag(@restaurant, {})
  client_etag = request.headers['If-None-Match']
  
  Rails.logger.debug "Generated ETag: #{etag}"
  Rails.logger.debug "Client ETag: #{client_etag}"
  Rails.logger.debug "Match: #{etag == client_etag}"
  
  return if cache_with_etag(@restaurant)
  render :show
end
```

### Issue: Cache Statistics Not Updating

**Check:**
1. Verify analytics service is enabled
2. Check if requests are being tracked
3. Verify Redis is running

**Solution:**
```bash
# Reset and monitor
bundle exec rake browser_cache:reset_stats
bundle exec rake browser_cache:test
bundle exec rake browser_cache:stats
```

## Advanced Configuration

### Custom Cache TTLs by Content Type

```ruby
# In BrowserCacheService
def set_html_headers(response, current_user)
  if current_user
    response.headers['Cache-Control'] = 'private, must-revalidate, max-age=0'
  else
    # Increase public page cache time
    response.headers['Cache-Control'] = 'public, max-age=300, must-revalidate'
  end
end
```

### Custom ETag Generation

```ruby
# In controller
def generate_custom_etag(resource)
  # Include additional factors in ETag
  components = [
    resource.cache_key_with_version,
    current_user&.id,
    I18n.locale,
    Time.current.to_date.to_s
  ]
  
  Digest::MD5.hexdigest(components.join('-'))
end

def show
  etag = generate_custom_etag(@restaurant)
  return head :not_modified if request.headers['If-None-Match'] == etag
  
  response.headers['ETag'] = etag
  render :show
end
```

### Conditional Cache Warming

```ruby
# Warm cache based on user activity patterns
def show
  @restaurant = Restaurant.find(params[:id])
  
  # Warm related data if user is likely to access it
  if user_likely_to_view_menus?
    warm_menu_cache_async(@restaurant.id)
  end
  
  return if cache_with_etag(@restaurant)
  render :show
end

private

def user_likely_to_view_menus?
  # Check user's recent activity
  session[:recent_menu_views].to_i > 3
end
```

## Summary

The L4 Browser Cache system is now **fully operational** and provides:

✅ **Automatic cache headers** for all content types  
✅ **ETag support** for conditional requests  
✅ **304 Not Modified** responses for unchanged resources  
✅ **Service worker** enhancements for offline support  
✅ **Performance monitoring** and analytics  
✅ **Rake tasks** for cache management  

**No additional configuration needed** - the system works automatically across all controllers!

For questions or issues, check the troubleshooting section or run:
```bash
bundle exec rake browser_cache:test
```
