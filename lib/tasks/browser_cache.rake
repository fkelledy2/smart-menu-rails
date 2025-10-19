# frozen_string_literal: true

namespace :browser_cache do
  desc 'Show browser cache statistics'
  task stats: :environment do
    puts "\n=== Browser Cache Statistics ===\n\n"
    
    summary = BrowserCacheAnalyticsService.performance_summary
    
    puts "Total Requests: #{summary[:total_requests]}"
    puts "Cached Responses: #{summary[:cached_responses]}"
    puts "No-Cache Responses: #{summary[:no_cache_responses]}"
    puts "304 Not Modified: #{summary[:not_modified_responses]}"
    puts "ETag Responses: #{summary[:etag_responses]}"
    puts "\nPerformance Metrics:"
    puts "  Cache Hit Rate: #{summary[:cache_hit_rate]}%"
    puts "  ETag Validation Rate: #{summary[:etag_validation_rate]}%"
    puts "  304 Not Modified Rate: #{summary[:not_modified_rate]}%"
    
    puts "\nBy Content Type:"
    summary[:by_content_type].each do |type, count|
      puts "  #{type}: #{count}"
    end
    
    puts "\nBy Status Code:"
    summary[:by_status].each do |status, count|
      puts "  #{status}: #{count}"
    end
    
    puts "\n"
  end

  desc 'Show browser cache health status'
  task health: :environment do
    puts "\n=== Browser Cache Health Check ===\n\n"
    
    health = BrowserCacheAnalyticsService.cache_health
    
    status_emoji = case health[:status]
                   when 'excellent' then '🟢'
                   when 'good' then '🟡'
                   when 'fair' then '🟠'
                   else '🔴'
                   end
    
    puts "Status: #{status_emoji} #{health[:status].upcase}"
    puts "\nMetrics:"
    puts "  Cache Hit Rate: #{health[:cache_hit_rate]}%"
    puts "  ETag Validation Rate: #{health[:etag_validation_rate]}%"
    puts "  304 Not Modified Rate: #{health[:not_modified_rate]}%"
    puts "  Total Requests: #{health[:total_requests]}"
    
    puts "\nRecommendations:"
    health[:recommendations].each do |recommendation|
      puts "  • #{recommendation}"
    end
    
    puts "\n"
  end

  desc 'Reset browser cache statistics'
  task reset_stats: :environment do
    puts 'Resetting browser cache statistics...'
    BrowserCacheAnalyticsService.reset_stats
    puts '✓ Statistics reset successfully'
  end

  desc 'Test browser cache configuration'
  task test: :environment do
    puts "\n=== Browser Cache Configuration Test ===\n\n"
    
    # Test service initialization
    puts 'Testing BrowserCacheService...'
    service = BrowserCacheService.instance
    puts "✓ BrowserCacheService initialized"
    
    # Test analytics service
    puts 'Testing BrowserCacheAnalyticsService...'
    analytics = BrowserCacheAnalyticsService.instance
    puts "✓ BrowserCacheAnalyticsService initialized"
    
    # Test cache stats
    puts 'Testing cache statistics...'
    stats = BrowserCacheService.cache_stats
    puts "✓ Cache stats retrieved: #{stats[:total_requests]} requests"
    
    # Test performance summary
    puts 'Testing performance summary...'
    summary = BrowserCacheAnalyticsService.performance_summary
    puts "✓ Performance summary retrieved"
    
    # Test health check
    puts 'Testing health check...'
    health = BrowserCacheAnalyticsService.cache_health
    puts "✓ Health check completed: #{health[:status]}"
    
    puts "\n✓ All tests passed!\n\n"
  end

  desc 'Show browser cache configuration'
  task config: :environment do
    puts "\n=== Browser Cache Configuration ===\n\n"
    
    puts "Environment: #{Rails.env}"
    puts "Cache Store: #{Rails.cache.class.name}"
    
    puts "\nCache Header Strategies:"
    puts "  HTML: private, must-revalidate, max-age=0 (authenticated)"
    puts "        public, max-age=60 (public)"
    puts "  JSON API: private, max-age=300 (cacheable endpoints)"
    puts "            no-cache (sensitive endpoints)"
    puts "  JavaScript: public, max-age=31536000, immutable"
    puts "  CSS: public, max-age=31536000, immutable"
    puts "  Images: public, max-age=86400, immutable"
    
    puts "\nETag Support:"
    puts "  Enabled: Yes"
    puts "  Weak ETags: Supported"
    puts "  Strong ETags: Supported"
    
    puts "\nConditional Requests:"
    puts "  If-None-Match: Supported"
    puts "  304 Not Modified: Enabled"
    
    puts "\nSecurity Headers:"
    puts "  X-Content-Type-Options: nosniff"
    
    puts "\n"
  end

  desc 'Warm browser cache for critical resources'
  task warm: :environment do
    puts "\n=== Warming Browser Cache ===\n\n"
    
    puts 'Note: Browser cache warming is handled by the service worker'
    puts 'Critical resources are cached on first visit'
    puts 'Service worker pre-caches static assets automatically'
    
    puts "\nTo test service worker caching:"
    puts "  1. Visit the application in a browser"
    puts "  2. Open DevTools > Application > Service Workers"
    puts "  3. Check Cache Storage for cached resources"
    
    puts "\n"
  end

  desc 'Analyze cache performance'
  task analyze: :environment do
    puts "\n=== Browser Cache Performance Analysis ===\n\n"
    
    summary = BrowserCacheAnalyticsService.performance_summary
    health = BrowserCacheAnalyticsService.cache_health
    
    # Overall performance
    puts "Overall Performance: #{health[:status].upcase}"
    puts "━" * 50
    
    # Cache effectiveness
    puts "\nCache Effectiveness:"
    cache_hit_rate = summary[:cache_hit_rate]
    puts "  Cache Hit Rate: #{cache_hit_rate}% #{rate_indicator(cache_hit_rate, 80, 60)}"
    
    etag_rate = summary[:etag_validation_rate]
    puts "  ETag Validation: #{etag_rate}% #{rate_indicator(etag_rate, 70, 50)}"
    
    not_modified_rate = summary[:not_modified_rate]
    puts "  304 Not Modified: #{not_modified_rate}% #{rate_indicator(not_modified_rate, 50, 30)}"
    
    # Request distribution
    puts "\nRequest Distribution:"
    total = summary[:total_requests]
    if total > 0
      cached_pct = (summary[:cached_responses].to_f / total * 100).round(1)
      no_cache_pct = (summary[:no_cache_responses].to_f / total * 100).round(1)
      not_modified_pct = (summary[:not_modified_responses].to_f / total * 100).round(1)
      
      puts "  Cached: #{cached_pct}%"
      puts "  No-Cache: #{no_cache_pct}%"
      puts "  304 Not Modified: #{not_modified_pct}%"
    else
      puts "  No data available yet"
    end
    
    # Content type breakdown
    puts "\nTop Content Types:"
    summary[:by_content_type].sort_by { |_, count| -count }.first(5).each do |type, count|
      percentage = (count.to_f / total * 100).round(1)
      puts "  #{type}: #{count} (#{percentage}%)"
    end
    
    # Recommendations
    puts "\nRecommendations:"
    health[:recommendations].each do |rec|
      puts "  • #{rec}"
    end
    
    puts "\n"
  end

  private

  def rate_indicator(rate, excellent_threshold, good_threshold)
    if rate >= excellent_threshold
      '🟢 Excellent'
    elsif rate >= good_threshold
      '🟡 Good'
    else
      '🔴 Needs Improvement'
    end
  end
end
