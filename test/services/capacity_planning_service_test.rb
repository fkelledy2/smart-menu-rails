# frozen_string_literal: true

require 'test_helper'

class CapacityPlanningServiceTest < ActiveSupport::TestCase
  test 'calculates capacity for 1x growth' do
    capacity = CapacityPlanningService.calculate_capacity(1)

    assert_equal 1, capacity[:growth_multiplier]
    assert_not_nil capacity[:metrics]
    assert_not_nil capacity[:infrastructure]
    assert_not_nil capacity[:costs]
    assert_not_nil capacity[:recommendations]

    # Verify metrics scale correctly
    assert_equal 100, capacity[:metrics][:active_restaurants]
    assert_equal 1_000, capacity[:metrics][:peak_concurrent_users]
    assert_equal 5_000, capacity[:metrics][:avg_orders_per_hour]
  end

  test 'calculates capacity for 10x growth' do
    capacity = CapacityPlanningService.calculate_capacity(10)

    assert_equal 10, capacity[:growth_multiplier]

    # Verify metrics scale correctly
    assert_equal 1_000, capacity[:metrics][:active_restaurants]
    assert_equal 10_000, capacity[:metrics][:peak_concurrent_users]
    assert_equal 50_000, capacity[:metrics][:avg_orders_per_hour]

    # Verify infrastructure scales up
    assert_operator capacity[:infrastructure][:app_servers][:count], :>=, 4
    assert_operator capacity[:infrastructure][:database][:replicas], :>=, 1
    assert capacity[:infrastructure][:cdn]
  end

  test 'calculates capacity for 100x growth' do
    capacity = CapacityPlanningService.calculate_capacity(100)

    assert_equal 100, capacity[:growth_multiplier]

    # Verify metrics scale correctly
    assert_equal 10_000, capacity[:metrics][:active_restaurants]
    assert_equal 100_000, capacity[:metrics][:peak_concurrent_users]
    assert_equal 500_000, capacity[:metrics][:avg_orders_per_hour]

    # Verify infrastructure scales significantly
    assert_operator capacity[:infrastructure][:app_servers][:count], :>=, 10
    assert_operator capacity[:infrastructure][:database][:replicas], :>=, 4
    assert capacity[:infrastructure][:cdn]
    assert capacity[:infrastructure][:message_queue]
    assert capacity[:infrastructure][:database][:sharding]
  end

  test 'generates comprehensive report' do
    report = CapacityPlanningService.generate_report([1, 10, 100])

    assert_not_nil report[:generated_at]
    assert_not_nil report[:current_baseline]
    assert_not_nil report[:scenarios]

    assert_includes report[:scenarios].keys, '1x'
    assert_includes report[:scenarios].keys, '10x'
    assert_includes report[:scenarios].keys, '100x'

    # Verify each scenario has required data
    report[:scenarios].each_value do |scenario|
      assert_not_nil scenario[:metrics]
      assert_not_nil scenario[:infrastructure]
      assert_not_nil scenario[:costs]
      assert_not_nil scenario[:recommendations]
    end
  end

  test 'calculates costs correctly' do
    capacity_1x = CapacityPlanningService.calculate_capacity(1)
    capacity_10x = CapacityPlanningService.calculate_capacity(10)
    capacity_100x = CapacityPlanningService.calculate_capacity(100)

    # Costs should increase with scale
    assert_operator capacity_10x[:costs][:total_monthly], :>, capacity_1x[:costs][:total_monthly]
    assert_operator capacity_100x[:costs][:total_monthly], :>, capacity_10x[:costs][:total_monthly]

    # Verify cost structure
    assert capacity_1x[:costs][:app_servers].positive?
    assert capacity_1x[:costs][:database].positive?
    assert capacity_1x[:costs][:cache].positive?
    assert capacity_1x[:costs][:total_monthly].positive?
    assert capacity_1x[:costs][:total_annual].positive?

    # Annual should be 12x monthly
    assert_equal capacity_1x[:costs][:total_monthly] * 12, capacity_1x[:costs][:total_annual]
  end

  test 'provides appropriate recommendations for different scales' do
    capacity_1x = CapacityPlanningService.calculate_capacity(1)
    capacity_10x = CapacityPlanningService.calculate_capacity(10)
    capacity_100x = CapacityPlanningService.calculate_capacity(100)

    # 1x should have minimal recommendations
    assert_includes capacity_1x[:recommendations].join(' '), 'sufficient'

    # 10x should recommend scaling strategies
    recommendations_10x = capacity_10x[:recommendations].join(' ')
    assert_includes recommendations_10x.downcase, 'shard' || recommendations_10x.downcase.include?('replica')

    # 100x should recommend advanced strategies
    recommendations_100x = capacity_100x[:recommendations].join(' ')
    assert_includes recommendations_100x.downcase, 'shard'
    assert_includes recommendations_100x.downcase, 'multi-region' || recommendations_100x.downcase.include?('cdn')
  end

  test 'can_handle_load returns correct assessment' do
    # Current capacity should handle current load
    result_current = CapacityPlanningService.can_handle_load?(1_000)
    assert result_current[:can_handle]

    # Should handle 2x load
    result_2x = CapacityPlanningService.can_handle_load?(2_000)
    assert result_2x[:can_handle]

    # Should not handle 10x load without upgrades
    result_10x = CapacityPlanningService.can_handle_load?(10_000)
    assert_not result_10x[:can_handle]
    assert_not_nil result_10x[:required_infrastructure]
    assert_not_nil result_10x[:estimated_cost]
  end

  test 'infrastructure scales appropriately at different levels' do
    # Test infrastructure scaling at key thresholds
    capacity_2x = CapacityPlanningService.calculate_capacity(2)
    capacity_5x = CapacityPlanningService.calculate_capacity(5)
    capacity_10x = CapacityPlanningService.calculate_capacity(10)
    capacity_50x = CapacityPlanningService.calculate_capacity(50)

    # App servers should increase
    assert_operator capacity_5x[:infrastructure][:app_servers][:count],
                    :>,
                    capacity_2x[:infrastructure][:app_servers][:count]

    # Database replicas should increase
    assert_operator capacity_10x[:infrastructure][:database][:replicas],
                    :>,
                    capacity_5x[:infrastructure][:database][:replicas]

    # Cache should scale
    assert_operator capacity_50x[:infrastructure][:cache][:size_gb],
                    :>,
                    capacity_10x[:infrastructure][:cache][:size_gb]
  end

  test 'current_utilization returns valid data structure' do
    utilization = CapacityPlanningService.current_utilization

    assert_not_nil utilization[:timestamp]
    assert_kind_of Time, utilization[:timestamp]

    # Database utilization may be empty if not available
    if utilization[:database].present?
      assert_kind_of Hash, utilization[:database]
    end

    # Cache utilization may be empty if Redis not available
    if utilization[:cache].present?
      assert_kind_of Hash, utilization[:cache]
    end

    # Application utilization may be empty if not available
    if utilization[:application].present?
      assert_kind_of Hash, utilization[:application]
    end
  end

  test 'metrics scale proportionally' do
    capacity_1x = CapacityPlanningService.calculate_capacity(1)
    capacity_10x = CapacityPlanningService.calculate_capacity(10)

    # Verify proportional scaling
    assert_equal capacity_1x[:metrics][:active_restaurants] * 10,
                 capacity_10x[:metrics][:active_restaurants]

    assert_equal capacity_1x[:metrics][:peak_concurrent_users] * 10,
                 capacity_10x[:metrics][:peak_concurrent_users]

    assert_equal capacity_1x[:metrics][:avg_orders_per_hour] * 10,
                 capacity_10x[:metrics][:avg_orders_per_hour]
  end

  test 'infrastructure includes autoscaling for high growth' do
    capacity_10x = CapacityPlanningService.calculate_capacity(10)
    capacity_100x = CapacityPlanningService.calculate_capacity(100)

    # 10x should have autoscaling
    if capacity_10x[:infrastructure][:app_servers][:autoscaling]
      assert_not_nil capacity_10x[:infrastructure][:app_servers][:autoscaling][:min]
      assert_not_nil capacity_10x[:infrastructure][:app_servers][:autoscaling][:max]
      assert_operator capacity_10x[:infrastructure][:app_servers][:autoscaling][:max],
                      :>,
                      capacity_10x[:infrastructure][:app_servers][:autoscaling][:min]
    end

    # 100x must have autoscaling
    assert_not_nil capacity_100x[:infrastructure][:app_servers][:autoscaling]
    assert_operator capacity_100x[:infrastructure][:app_servers][:autoscaling][:max],
                    :>,
                    capacity_100x[:infrastructure][:app_servers][:count]
  end

  test 'cost estimates are reasonable' do
    capacity_1x = CapacityPlanningService.calculate_capacity(1)
    capacity_10x = CapacityPlanningService.calculate_capacity(10)
    capacity_100x = CapacityPlanningService.calculate_capacity(100)

    # 1x should be affordable for small deployment
    assert_operator capacity_1x[:costs][:total_monthly], :<, 1_000

    # 10x should be reasonable for medium business
    assert_operator capacity_10x[:costs][:total_monthly], :<, 5_000

    # 100x will be expensive but should be under $50k/month
    assert_operator capacity_100x[:costs][:total_monthly], :<, 50_000

    # Costs should scale sub-linearly (economies of scale)
    cost_ratio_10x = capacity_10x[:costs][:total_monthly].to_f / capacity_1x[:costs][:total_monthly]
    cost_ratio_100x = capacity_100x[:costs][:total_monthly].to_f / capacity_10x[:costs][:total_monthly]

    # 10x traffic should not cost 10x as much
    assert_operator cost_ratio_10x, :<, 10
    assert_operator cost_ratio_100x, :<, 10
  end
end
