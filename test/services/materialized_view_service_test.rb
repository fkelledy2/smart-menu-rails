require 'test_helper'

class MaterializedViewServiceTest < ActiveSupport::TestCase
  def setup
    @service = MaterializedViewService.instance
  end

  test 'should have correct materialized views configuration' do
    expected_views = %w[restaurant_analytics_mv menu_performance_mv system_analytics_mv dw_orders_mv]

    assert_equal expected_views.sort, MaterializedViewService::MATERIALIZED_VIEWS.keys.sort

    # Check that each view has required configuration
    MaterializedViewService::MATERIALIZED_VIEWS.each do |view_name, config|
      assert config.key?(:frequency), "#{view_name} missing frequency config"
      assert config.key?(:priority), "#{view_name} missing priority config"
      assert config[:frequency].is_a?(ActiveSupport::Duration), "#{view_name} frequency should be a duration"
      assert %i[high medium low].include?(config[:priority]), "#{view_name} priority should be high, medium, or low"
    end
  end

  test 'should validate view names' do
    # Valid view name should not raise error
    assert_nothing_raised do
      @service.send(:validate_view_name!, 'restaurant_analytics_mv')
    end

    # Invalid view name should raise error
    assert_raises ArgumentError do
      @service.send(:validate_view_name!, 'invalid_view')
    end
  end

  test 'should identify views supporting concurrent refresh' do
    # These views should support concurrent refresh
    assert @service.send(:supports_concurrent_refresh?, 'restaurant_analytics_mv')
    assert @service.send(:supports_concurrent_refresh?, 'menu_performance_mv')

    # These views should not support concurrent refresh (for now)
    assert_not @service.send(:supports_concurrent_refresh?, 'system_analytics_mv')
    assert_not @service.send(:supports_concurrent_refresh?, 'dw_orders_mv')
  end

  test 'should get view statistics' do
    # Test getting stats for a specific view
    stats = @service.view_statistics('restaurant_analytics_mv')

    if stats[:exists] == false
      # View doesn't exist yet (before migration)
      assert_equal 'View not found', stats[:error]
    else
      assert_equal 'restaurant_analytics_mv', stats[:name]
      assert stats.key?(:size)
      assert stats.key?(:last_refresh)
      assert stats.key?(:frequency)
      assert stats.key?(:priority)
    end
  end

  test 'should get statistics for all views' do
    all_stats = @service.view_statistics

    assert_equal MaterializedViewService::MATERIALIZED_VIEWS.size, all_stats.size

    all_stats.each do |stats|
      assert stats.key?(:name)
      assert MaterializedViewService::MATERIALIZED_VIEWS.key?(stats[:name])
    end
  end

  test 'should perform health check' do
    health_check = @service.health_check

    assert health_check.key?(:overall_status)
    assert %i[healthy degraded unhealthy].include?(health_check[:overall_status])

    assert health_check.key?(:views)
    assert health_check.key?(:summary)

    summary = health_check[:summary]
    assert summary.key?(:total_views)
    assert summary.key?(:healthy_views)
    assert summary.key?(:stale_views)
    assert summary.key?(:failed_views)

    assert_equal MaterializedViewService::MATERIALIZED_VIEWS.size, summary[:total_views]
  end

  test 'should identify views needing refresh' do
    # This test is hard to verify without actual data, but we can check the structure
    needing_refresh = @service.views_needing_refresh

    assert needing_refresh.is_a?(Array)

    # If any views need refresh, check the structure
    if needing_refresh.any?
      first_view = needing_refresh.first
      assert first_view.key?(:view)
      assert first_view.key?(:last_refresh)
      assert first_view.key?(:frequency)
      assert first_view.key?(:overdue_by)
    end
  end

  test 'should handle refresh view with invalid name' do
    assert_raises ArgumentError do
      @service.refresh_view('invalid_view')
    end
  end

  test 'should handle refresh by priority' do
    # Test with valid priority levels
    %i[high medium low].each do |priority|
      result = @service.refresh_by_priority(priority, concurrently: false)

      assert result.is_a?(Hash)

      # Check that only views with the correct priority were processed
      expected_views = MaterializedViewService::MATERIALIZED_VIEWS
        .select { |_, config| config[:priority] == priority }
        .keys

      assert_equal expected_views.sort, result.keys.sort
    end
  end

  test 'should track refresh metrics' do
    # Test that metrics tracking doesn't raise errors
    assert_nothing_raised do
      @service.send(:track_refresh_metrics, 'test_view', 1.5, :success)
    end

    assert_nothing_raised do
      @service.send(:track_refresh_metrics, 'test_view', 2.0, :failure, 'Test error')
    end
  end

  test 'should check view health correctly' do
    # Mock a view configuration
    config = { frequency: 30.minutes, priority: :high }

    # Test with a healthy view (recently refreshed)
    @service.stub(:get_single_view_stats, {
      exists: true,
      last_refresh: 10.minutes.ago,
    },) do
      health = @service.send(:check_view_health, 'test_view', config)
      assert_equal :healthy, health[:status]
    end

    # Test with a stale view (not refreshed for too long)
    @service.stub(:get_single_view_stats, {
      exists: true,
      last_refresh: 2.hours.ago,
    },) do
      health = @service.send(:check_view_health, 'test_view', config)
      assert_equal :stale, health[:status]
      assert health[:reason].include?('Last refreshed')
    end

    # Test with a non-existent view
    @service.stub(:get_single_view_stats, { exists: false }) do
      health = @service.send(:check_view_health, 'test_view', config)
      assert_equal :failed, health[:status]
      assert_equal 'View not found', health[:reason]
    end
  end

  test 'should get last refresh time' do
    # This method queries the database, so we'll just test it doesn't raise errors
    assert_nothing_raised do
      refresh_time = @service.send(:get_last_refresh_time, 'restaurant_analytics_mv')
      assert refresh_time.is_a?(Time)
    end
  end
end
