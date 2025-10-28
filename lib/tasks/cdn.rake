namespace :cdn do
  desc 'Purge entire CDN cache'
  task purge_all: :environment do
    puts '🔥 Purging entire CDN cache...'

    if CdnPurgeService.purge_all
      puts '✅ CDN cache purged successfully!'
    else
      puts '❌ Failed to purge CDN cache'
      exit 1
    end
  end

  desc 'Purge asset files from CDN'
  task purge_assets: :environment do
    puts '🔥 Purging asset files from CDN...'

    if CdnPurgeService.purge_assets
      puts '✅ Asset cache purged successfully!'
    else
      puts '❌ Failed to purge asset cache'
      exit 1
    end
  end

  desc 'Purge specific URLs from CDN (comma-separated)'
  task :purge_urls, [:urls] => :environment do |_t, args|
    if args[:urls].blank?
      puts '❌ Please provide URLs to purge (comma-separated)'
      puts 'Usage: rake cdn:purge_urls["https://example.com/asset1.js,https://example.com/asset2.css"]'
      exit 1
    end

    urls = args[:urls].split(',').map(&:strip)
    puts "🔥 Purging #{urls.size} URLs from CDN..."

    if CdnPurgeService.purge_urls(urls)
      puts '✅ URLs purged successfully!'
    else
      puts '❌ Failed to purge URLs'
      exit 1
    end
  end

  desc 'Purge CDN cache by pattern'
  task :purge_pattern, [:pattern] => :environment do |_t, args|
    if args[:pattern].blank?
      puts '❌ Please provide a pattern to purge'
      puts 'Usage: rake cdn:purge_pattern["assets/*.js"]'
      exit 1
    end

    puts "🔥 Purging CDN cache by pattern: #{args[:pattern]}"

    if CdnPurgeService.purge_by_pattern(args[:pattern])
      puts '✅ Pattern purged successfully!'
    else
      puts '❌ Failed to purge pattern'
      exit 1
    end
  end

  desc 'Show CDN statistics'
  task stats: :environment do
    puts '📊 CDN Statistics:'
    puts '=' * 50

    stats = CdnPurgeService.instance.cdn_stats

    puts "Enabled: #{stats[:enabled] ? '✅ Yes' : '❌ No'}"
    puts "Provider: #{stats[:provider]}"
    puts "Asset Host: #{stats[:asset_host] || 'Not configured'}"
    puts "Cloudflare Configured: #{stats[:cloudflare_configured] ? '✅ Yes' : '❌ No'}"

    if stats[:enabled]
      puts "\n📈 Performance Metrics:"
      puts '=' * 50

      performance = CdnAnalyticsService.performance_summary

      puts "Cache Hit Rate: #{performance[:cache_hit_rate]}%"
      puts "Bandwidth Saved: #{performance[:bandwidth_saved]}%"
      puts "Total Requests: #{performance[:total_requests].to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
      puts "Cached Requests: #{performance[:cached_requests].to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
      puts "Total Bandwidth: #{performance[:bandwidth_mb]} MB"
      puts "Cached Bandwidth: #{performance[:cached_bandwidth_mb]} MB"
      puts "Avg Response Time: #{performance[:average_response_time]} ms"
    end
  end

  desc 'Check CDN health'
  task health: :environment do
    puts '🏥 CDN Health Check:'
    puts '=' * 50

    health = CdnAnalyticsService.health_check

    status_icon = case health[:status]
                  when 'healthy' then '✅'
                  when 'degraded' then '⚠️'
                  when 'unhealthy' then '❌'
                  when 'disabled' then '🔌'
                  else '❓'
                  end

    puts "Status: #{status_icon} #{health[:status].upcase}"
    puts "Provider: #{health[:provider]}"
    puts "Asset Host: #{health[:asset_host] || 'Not configured'}"
    puts "CDN Enabled: #{health[:cdn_enabled] ? '✅ Yes' : '❌ No'}"
    puts "Cache Hit Rate: #{health[:cache_hit_rate]}%"
    puts "Last Check: #{health[:last_check]}"

    if health[:status] == 'unhealthy'
      puts "\n⚠️  CDN is not responding correctly. Please check configuration."
      exit 1
    end
  end

  desc 'Test CDN configuration'
  task test: :environment do
    puts '🧪 Testing CDN Configuration:'
    puts '=' * 50

    # Check if asset_host is configured
    asset_host = Rails.application.config.asset_host || ENV.fetch('CDN_HOST', nil)

    if asset_host.blank?
      puts '❌ Asset host not configured'
      puts 'Set config.asset_host in production.rb or CDN_HOST environment variable'
      exit 1
    end

    puts "✅ Asset host configured: #{asset_host}"

    # Test CDN connectivity
    puts "\n🔍 Testing CDN connectivity..."
    health = CdnAnalyticsService.health_check

    if health[:status] == 'healthy'
      puts '✅ CDN is responding correctly'
    else
      puts "❌ CDN health check failed: #{health[:status]}"
      exit 1
    end

    # Test purge service
    puts "\n🔍 Testing purge service..."
    if CdnPurgeService.instance.cdn_enabled?
      puts '✅ Purge service is available'
    else
      puts '❌ Purge service is not available'
      exit 1
    end

    puts "\n✅ All CDN tests passed!"
  end

  desc 'Show CDN configuration'
  task config: :environment do
    puts '⚙️  CDN Configuration:'
    puts '=' * 50

    puts "Environment: #{Rails.env}"
    puts "Asset Host: #{Rails.application.config.asset_host || 'Not set'}"
    puts "CDN_HOST ENV: #{ENV['CDN_HOST'] || 'Not set'}"
    puts "Assets Compile: #{Rails.application.config.assets.compile}"
    puts "Assets Digest: #{Rails.application.config.assets.digest}"

    if Rails.application.config.public_file_server.headers
      puts "\nCache Headers:"
      Rails.application.config.public_file_server.headers.each do |key, value|
        puts "  #{key}: #{value}"
      end
    end

    puts "\nCDN Provider: #{CdnPurgeService.instance.send(:cdn_provider)}"
    puts "Cloudflare Configured: #{CdnPurgeService.instance.cloudflare_enabled? ? '✅ Yes' : '❌ No'}"
  end
end
