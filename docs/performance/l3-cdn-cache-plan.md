# L3 CDN Cache Implementation Plan

## 🎯 Executive Summary

Implement L3 (Level 3) CDN caching layer to optimize static content delivery, reduce server load, and improve global performance through edge caching.

**Current Status**: Static assets served directly from application server  
**Target**: CDN-powered asset delivery with edge caching, automatic invalidation, and optimized cache headers

---

## 📊 Current State Analysis

### ✅ Existing Infrastructure

#### **Asset Pipeline**
- Rails asset pipeline with Sprockets
- JavaScript bundling with esbuild
- CSS compilation with Sass + PostCSS
- Asset fingerprinting enabled in production

#### **Current Configuration**
```ruby
# config/environments/production.rb
config.assets.compile = false
config.public_file_server.headers = {
  'Cache-Control' => 'public, max-age=31536000',
  'Expires' => 1.year.from_now.to_formatted_s(:rfc822)
}
```

#### **Static Assets**
- JavaScript bundles in `app/assets/builds/`
- CSS files in `app/assets/builds/`
- Images in `app/assets/images/`
- Fonts and other static files in `public/`

#### **Storage**
- Active Storage configured with S3 (Amazon)
- User-uploaded content stored on S3
- Image processing with libvips

### ❌ Gaps Identified

1. **No CDN Integration**
   - Assets served directly from application server
   - No edge caching for global users
   - High latency for international users

2. **No Asset Host Configuration**
   - `config.asset_host` not configured
   - Assets not served from CDN domain

3. **Limited Cache Control**
   - Basic cache headers only
   - No CDN-specific headers (e.g., `CDN-Cache-Control`)
   - No stale-while-revalidate strategy

4. **No CDN Purging**
   - No automated cache invalidation
   - Manual purging required for updates

5. **No CDN Analytics**
   - No visibility into CDN performance
   - No cache hit rate monitoring

---

## 🎯 Implementation Strategy

### **Phase 1: CDN Provider Selection & Setup**

#### **Recommended Provider: Cloudflare**
**Rationale:**
- Free tier available for testing
- Excellent Rails integration
- Automatic HTTPS
- Built-in DDoS protection
- Global edge network (300+ locations)
- Easy DNS management
- API for programmatic cache purging

**Alternative: AWS CloudFront**
- Better S3 integration
- More granular control
- Pay-as-you-go pricing

#### **Tasks**

**1.1 Cloudflare Setup**
```bash
# 1. Sign up for Cloudflare account
# 2. Add domain (mellow.menu)
# 3. Update DNS nameservers
# 4. Enable CDN (orange cloud)
# 5. Configure SSL/TLS (Full or Full Strict)
```

**1.2 DNS Configuration**
```
# Cloudflare DNS Records
A     @              <server-ip>     Proxied (orange cloud)
A     www            <server-ip>     Proxied (orange cloud)
CNAME assets         @               Proxied (orange cloud)
```

---

### **Phase 2: Rails CDN Integration**

#### **Objectives**
- Configure asset_host for CDN delivery
- Add CDN-specific cache headers
- Implement asset fingerprinting verification
- Add CORS headers for cross-origin assets

#### **Tasks**

**2.1 Configure Asset Host**
```ruby
# config/environments/production.rb
config.asset_host = ENV.fetch('CDN_HOST', 'https://assets.mellow.menu')

# Or use Cloudflare subdomain
config.asset_host = 'https://mellow.menu'
```

**2.2 Enhanced Cache Headers**
```ruby
# config/initializers/cdn_cache_headers.rb
Rails.application.config.to_prepare do
  # Set CDN-specific headers
  ActionDispatch::Static.new(
    Rails.application,
    Rails.public_path,
    headers: {
      'Cache-Control' => 'public, max-age=31536000, immutable',
      'CDN-Cache-Control' => 'public, max-age=31536000',
      'Cloudflare-CDN-Cache-Control' => 'max-age=31536000',
      'Vary' => 'Accept-Encoding',
      'X-Content-Type-Options' => 'nosniff'
    }
  )
end
```

**2.3 CORS Configuration**
```ruby
# config/initializers/cors.rb
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins '*'
    resource '/assets/*',
      headers: :any,
      methods: [:get, :options],
      max_age: 86400
  end
end
```

**2.4 Asset Fingerprinting Verification**
```ruby
# Ensure assets have unique fingerprints
config.assets.digest = true
config.assets.version = '1.0'
```

---

### **Phase 3: CDN Cache Optimization**

#### **Objectives**
- Implement intelligent cache rules
- Add cache warming strategies
- Configure cache bypass for development
- Optimize cache TTLs by content type

#### **Tasks**

**3.1 Cloudflare Page Rules**
```
# Rule 1: Cache Everything for Assets
URL: assets.mellow.menu/*
Settings:
  - Cache Level: Cache Everything
  - Edge Cache TTL: 1 year
  - Browser Cache TTL: 1 year

# Rule 2: Bypass Cache for Admin
URL: mellow.menu/admin/*
Settings:
  - Cache Level: Bypass

# Rule 3: Cache API Responses
URL: mellow.menu/api/*
Settings:
  - Cache Level: Cache Everything
  - Edge Cache TTL: 5 minutes
```

**3.2 Content-Type Specific TTLs**
```ruby
# config/initializers/cdn_cache_control.rb
module CdnCacheControl
  CACHE_DURATIONS = {
    'application/javascript' => 1.year,
    'text/css' => 1.year,
    'image/png' => 1.year,
    'image/jpeg' => 1.year,
    'image/svg+xml' => 1.year,
    'font/woff2' => 1.year,
    'application/json' => 5.minutes,
    'text/html' => 0 # Don't cache HTML
  }.freeze

  def self.cache_control_for(content_type)
    duration = CACHE_DURATIONS[content_type] || 1.hour
    "public, max-age=#{duration.to_i}, immutable"
  end
end
```

**3.3 Stale-While-Revalidate**
```ruby
# For dynamic content that can serve stale
response.headers['Cache-Control'] = 'public, max-age=300, stale-while-revalidate=86400'
```

---

### **Phase 4: CDN Purging & Invalidation**

#### **Objectives**
- Implement automated cache purging
- Add manual purge rake tasks
- Configure purge on deployment
- Add selective purging by URL pattern

#### **Tasks**

**4.1 Cloudflare API Integration**
```ruby
# Gemfile
gem 'cloudflare', '~> 4.3'

# config/initializers/cloudflare.rb
require 'cloudflare'

CLOUDFLARE_CLIENT = Cloudflare.connect(
  key: Rails.application.credentials.dig(:cloudflare, :api_key),
  email: Rails.application.credentials.dig(:cloudflare, :email)
)

CLOUDFLARE_ZONE_ID = Rails.application.credentials.dig(:cloudflare, :zone_id)
```

**4.2 CDN Purge Service**
```ruby
# app/services/cdn_purge_service.rb
class CdnPurgeService
  include Singleton

  def purge_all
    # Purge entire CDN cache
    CLOUDFLARE_CLIENT.zones.purge_cache(CLOUDFLARE_ZONE_ID, purge_everything: true)
  end

  def purge_urls(urls)
    # Purge specific URLs
    CLOUDFLARE_CLIENT.zones.purge_cache(CLOUDFLARE_ZONE_ID, files: urls)
  end

  def purge_assets
    # Purge all asset files
    purge_urls([
      "#{asset_host}/assets/*",
      "#{asset_host}/packs/*"
    ])
  end

  def purge_by_tag(tags)
    # Purge by cache tags
    CLOUDFLARE_CLIENT.zones.purge_cache(CLOUDFLARE_ZONE_ID, tags: tags)
  end

  private

  def asset_host
    Rails.application.config.asset_host
  end
end
```

**4.3 Rake Tasks for CDN Management**
```ruby
# lib/tasks/cdn.rake
namespace :cdn do
  desc 'Purge entire CDN cache'
  task purge_all: :environment do
    puts '🔥 Purging entire CDN cache...'
    CdnPurgeService.instance.purge_all
    puts '✅ CDN cache purged successfully!'
  end

  desc 'Purge asset files from CDN'
  task purge_assets: :environment do
    puts '🔥 Purging asset files from CDN...'
    CdnPurgeService.instance.purge_assets
    puts '✅ Asset cache purged successfully!'
  end

  desc 'Purge specific URLs from CDN'
  task :purge_urls, [:urls] => :environment do |t, args|
    urls = args[:urls].split(',')
    puts "🔥 Purging #{urls.size} URLs from CDN..."
    CdnPurgeService.instance.purge_urls(urls)
    puts '✅ URLs purged successfully!'
  end

  desc 'Warm CDN cache with critical assets'
  task warm_cache: :environment do
    puts '🔥 Warming CDN cache...'
    CdnCacheWarmingService.warm_critical_assets
    puts '✅ CDN cache warmed successfully!'
  end
end
```

**4.4 Automatic Purge on Deployment**
```ruby
# config/deploy.rb or GitHub Actions
after 'deploy:published', 'cdn:purge_assets'
```

---

### **Phase 5: CDN Monitoring & Analytics**

#### **Objectives**
- Track CDN performance metrics
- Monitor cache hit rates
- Analyze bandwidth savings
- Alert on CDN issues

#### **Tasks**

**5.1 CDN Analytics Service**
```ruby
# app/services/cdn_analytics_service.rb
class CdnAnalyticsService
  include Singleton

  def fetch_analytics(start_date: 7.days.ago, end_date: Time.current)
    # Fetch Cloudflare analytics
    analytics = CLOUDFLARE_CLIENT.zones.analytics.dashboard(
      CLOUDFLARE_ZONE_ID,
      since: start_date.iso8601,
      until: end_date.iso8601
    )

    {
      requests: analytics.dig('result', 'totals', 'requests', 'all'),
      bandwidth: analytics.dig('result', 'totals', 'bandwidth', 'all'),
      cached_requests: analytics.dig('result', 'totals', 'requests', 'cached'),
      cache_hit_rate: calculate_hit_rate(analytics),
      bandwidth_saved: calculate_bandwidth_saved(analytics)
    }
  end

  def cache_hit_rate
    analytics = fetch_analytics
    (analytics[:cached_requests].to_f / analytics[:requests] * 100).round(2)
  end

  private

  def calculate_hit_rate(analytics)
    total = analytics.dig('result', 'totals', 'requests', 'all')
    cached = analytics.dig('result', 'totals', 'requests', 'cached')
    return 0 if total.zero?
    (cached.to_f / total * 100).round(2)
  end

  def calculate_bandwidth_saved(analytics)
    total_bandwidth = analytics.dig('result', 'totals', 'bandwidth', 'all')
    cached_bandwidth = analytics.dig('result', 'totals', 'bandwidth', 'cached')
    (cached_bandwidth.to_f / total_bandwidth * 100).round(2)
  end
end
```

**5.2 CDN Health Check**
```ruby
# Add to HealthController
def cdn_health
  {
    status: check_cdn_status,
    cache_hit_rate: CdnAnalyticsService.instance.cache_hit_rate,
    asset_host: Rails.application.config.asset_host,
    cdn_enabled: cdn_enabled?
  }
end

private

def check_cdn_status
  # Test CDN connectivity
  uri = URI("#{Rails.application.config.asset_host}/assets/application.css")
  response = Net::HTTP.get_response(uri)
  response.code == '200' ? 'healthy' : 'degraded'
rescue StandardError
  'unhealthy'
end

def cdn_enabled?
  Rails.application.config.asset_host.present?
end
```

---

## 📊 Success Metrics

### **Performance Targets**
- ✅ **90% cache hit rate** for static assets
- ✅ **50% reduction** in origin server bandwidth
- ✅ **70% faster** asset loading for global users
- ✅ **<100ms TTFB** for cached assets

### **CDN Effectiveness**
- ✅ **Edge cache hit rate**: >85%
- ✅ **Bandwidth savings**: >60%
- ✅ **Global latency**: <200ms for 95th percentile
- ✅ **Origin offload**: >70% of asset requests

### **Cost Optimization**
- ✅ **Server bandwidth**: 50% reduction
- ✅ **Server CPU**: 30% reduction (fewer asset requests)
- ✅ **Hosting costs**: 20% reduction

---

## 🔧 Implementation Checklist

### **Week 1: Setup & Configuration**
- [ ] Sign up for Cloudflare account
- [ ] Configure DNS and enable CDN
- [ ] Set up SSL/TLS certificates
- [ ] Configure asset_host in Rails
- [ ] Test asset delivery through CDN

### **Week 2: Optimization**
- [ ] Implement enhanced cache headers
- [ ] Configure Cloudflare page rules
- [ ] Add CORS support
- [ ] Optimize cache TTLs by content type
- [ ] Test cache behavior

### **Week 3: Automation**
- [ ] Integrate Cloudflare API
- [ ] Implement CDN purge service
- [ ] Create rake tasks for CDN management
- [ ] Add deployment hooks for cache purging
- [ ] Test automated purging

### **Week 4: Monitoring & Testing**
- [ ] Implement CDN analytics service
- [ ] Add CDN health checks
- [ ] Create monitoring dashboard
- [ ] Write comprehensive tests
- [ ] Performance testing and validation

---

## 🚀 Usage Examples

### **Asset URLs with CDN**
```erb
<!-- Before CDN -->
<%= stylesheet_link_tag 'application' %>
<!-- Generates: /assets/application-abc123.css -->

<!-- After CDN -->
<%= stylesheet_link_tag 'application' %>
<!-- Generates: https://assets.mellow.menu/assets/application-abc123.css -->
```

### **Manual Cache Purging**
```bash
# Purge all CDN cache
bundle exec rake cdn:purge_all

# Purge only assets
bundle exec rake cdn:purge_assets

# Purge specific URLs
bundle exec rake cdn:purge_urls["https://mellow.menu/assets/app.js,https://mellow.menu/assets/app.css"]

# Warm cache
bundle exec rake cdn:warm_cache
```

### **Programmatic Purging**
```ruby
# In model callback
after_commit :purge_cdn_cache, on: [:update]

def purge_cdn_cache
  CdnPurgeService.instance.purge_urls([
    "#{Rails.application.config.asset_host}/menus/#{id}"
  ])
end
```

---

## 📚 Testing Strategy

### **Unit Tests**
- CDN purge service functionality
- Cache header generation
- URL construction with asset_host
- Analytics data parsing

### **Integration Tests**
- Asset delivery through CDN
- Cache header verification
- CORS functionality
- CDN health checks

### **Performance Tests**
- Asset load time comparison
- Cache hit rate measurement
- Bandwidth usage tracking
- Global latency testing

---

## 🎯 Expected Benefits

### **Performance**
- **70% faster** asset loading globally
- **50% reduction** in server bandwidth
- **<100ms** asset delivery from edge
- **Improved Core Web Vitals** scores

### **Scalability**
- **10x traffic handling** without server upgrades
- **Global edge caching** for international users
- **Reduced origin load** by 70%+
- **Better DDoS protection**

### **Cost Savings**
- **50% reduction** in bandwidth costs
- **30% reduction** in server CPU usage
- **20% reduction** in hosting costs
- **Free tier** available with Cloudflare

### **User Experience**
- **Faster page loads** worldwide
- **Better mobile performance**
- **Improved reliability** with edge caching
- **Automatic HTTPS** everywhere

---

## 🔒 Security Considerations

### **SSL/TLS**
- Full SSL/TLS encryption
- Automatic certificate management
- HSTS headers enabled
- TLS 1.3 support

### **DDoS Protection**
- Cloudflare's built-in DDoS protection
- Rate limiting at edge
- Bot protection
- WAF (Web Application Firewall)

### **Access Control**
- Signed URLs for private assets
- IP-based restrictions
- Geographic restrictions if needed
- API key security

---

## 🎯 Next Steps

1. Set up Cloudflare account and configure DNS
2. Configure Rails asset_host
3. Implement CDN purge service
4. Add monitoring and analytics
5. Write comprehensive tests
6. Deploy and monitor performance

**Estimated Total Time**: 4 weeks  
**Priority**: High (Performance & Scalability)
