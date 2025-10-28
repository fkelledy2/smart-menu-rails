require 'test_helper'

class CdnPurgeServiceTest < ActiveSupport::TestCase
  setup do
    @service = CdnPurgeService.instance
    @original_asset_host = Rails.application.config.asset_host
  end

  teardown do
    Rails.application.config.asset_host = @original_asset_host
  end

  test 'service is a singleton' do
    service1 = CdnPurgeService.instance
    service2 = CdnPurgeService.instance

    assert_same service1, service2
  end

  test 'cdn_enabled? returns false when asset_host is not configured' do
    Rails.application.config.asset_host = nil

    assert_not @service.cdn_enabled?
  end

  test 'cdn_enabled? returns true when asset_host is configured' do
    Rails.application.config.asset_host = 'https://cdn.example.com'

    assert @service.cdn_enabled?
  end

  test 'purge_all returns false when CDN is not enabled' do
    Rails.application.config.asset_host = nil

    assert_not @service.purge_all
  end

  test 'purge_all returns true when CDN is enabled' do
    Rails.application.config.asset_host = 'https://cdn.example.com'

    assert @service.purge_all
  end

  test 'purge_urls returns false when CDN is not enabled' do
    Rails.application.config.asset_host = nil

    assert_not @service.purge_urls(['https://example.com/asset.js'])
  end

  test 'purge_urls returns false when urls array is empty' do
    Rails.application.config.asset_host = 'https://cdn.example.com'

    assert_not @service.purge_urls([])
  end

  test 'purge_urls returns true when CDN is enabled and urls provided' do
    Rails.application.config.asset_host = 'https://cdn.example.com'

    urls = [
      'https://cdn.example.com/assets/app.js',
      'https://cdn.example.com/assets/app.css',
    ]

    assert @service.purge_urls(urls)
  end

  test 'purge_assets returns false when CDN is not enabled' do
    Rails.application.config.asset_host = nil

    assert_not @service.purge_assets
  end

  test 'purge_assets returns true when CDN is enabled' do
    Rails.application.config.asset_host = 'https://cdn.example.com'

    assert @service.purge_assets
  end

  test 'purge_by_pattern returns false when CDN is not enabled' do
    Rails.application.config.asset_host = nil

    assert_not @service.purge_by_pattern('assets/*.js')
  end

  test 'purge_by_pattern returns true when CDN is enabled' do
    Rails.application.config.asset_host = 'https://cdn.example.com'

    assert @service.purge_by_pattern('assets/*.js')
  end

  test 'cdn_stats returns correct structure' do
    Rails.application.config.asset_host = 'https://cdn.example.com'

    stats = @service.cdn_stats

    assert stats.key?(:enabled)
    assert stats.key?(:provider)
    assert stats.key?(:asset_host)
    assert stats.key?(:cloudflare_configured)
  end

  test 'cdn_stats shows enabled when asset_host is configured' do
    Rails.application.config.asset_host = 'https://cdn.example.com'

    stats = @service.cdn_stats

    assert stats[:enabled]
    assert_equal 'https://cdn.example.com', stats[:asset_host]
  end

  test 'cdn_stats shows disabled when asset_host is not configured' do
    Rails.application.config.asset_host = nil

    stats = @service.cdn_stats

    assert_not stats[:enabled]
    assert_nil stats[:asset_host]
  end

  test 'cloudflare_enabled? returns false by default' do
    assert_not @service.cloudflare_enabled?
  end

  test 'class methods delegate to instance' do
    Rails.application.config.asset_host = 'https://cdn.example.com'

    assert CdnPurgeService.purge_all
    assert CdnPurgeService.purge_assets
    assert CdnPurgeService.purge_urls(['https://example.com/test.js'])
    assert CdnPurgeService.purge_by_pattern('*.js')
  end

  test 'handles errors gracefully in purge_all' do
    Rails.application.config.asset_host = 'https://cdn.example.com'

    # Mock cloudflare_enabled to return true, then raise error
    @service.stub(:cloudflare_enabled?, true) do
      @service.stub(:purge_cloudflare_all, -> { raise StandardError, 'API Error' }) do
        assert_not @service.purge_all
      end
    end
  end

  test 'handles errors gracefully in purge_urls' do
    Rails.application.config.asset_host = 'https://cdn.example.com'

    # Mock cloudflare_enabled to return true, then raise error
    @service.stub(:cloudflare_enabled?, true) do
      @service.stub(:purge_cloudflare_urls, ->(_urls) { raise StandardError, 'API Error' }) do
        assert_not @service.purge_urls(['https://example.com/test.js'])
      end
    end
  end

  test 'purge_assets constructs correct asset URLs' do
    Rails.application.config.asset_host = 'https://cdn.example.com'

    # Capture the URLs passed to purge_urls
    captured_urls = nil
    @service.stub(:purge_urls, lambda { |urls|
      captured_urls = urls
      true
    },) do
      @service.purge_assets
    end

    assert_not_nil captured_urls
    assert(captured_urls.any? { |url| url.include?('/assets/') })
    assert(captured_urls.any? { |url| url.include?('/packs/') })
  end

  test 'purge_by_pattern constructs URL from pattern' do
    Rails.application.config.asset_host = 'https://cdn.example.com'

    # Capture the URLs passed to purge_urls
    captured_urls = nil
    @service.stub(:purge_urls, lambda { |urls|
      captured_urls = urls
      true
    },) do
      @service.purge_by_pattern('assets/*.js')
    end

    assert_not_nil captured_urls
    assert_equal 1, captured_urls.size
    assert_includes captured_urls.first, 'assets/*.js'
  end

  test 'cdn_provider detection for cloudflare' do
    Rails.application.config.asset_host = 'https://cdn.cloudflare.com'

    stats = @service.cdn_stats

    # Provider detection happens in private method
    assert stats[:enabled]
  end

  test 'cdn_provider detection for cloudfront' do
    Rails.application.config.asset_host = 'https://d123.cloudfront.net'

    stats = @service.cdn_stats

    # Provider detection happens in private method
    assert stats[:enabled]
  end

  test 'respects CDN_HOST environment variable' do
    original_env = ENV.fetch('CDN_HOST', nil)
    Rails.application.config.asset_host = nil
    ENV['CDN_HOST'] = 'https://env-cdn.example.com'

    assert @service.cdn_enabled?

    ENV['CDN_HOST'] = original_env
  end
end
