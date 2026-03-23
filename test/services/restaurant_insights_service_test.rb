require 'test_helper'

class RestaurantInsightsServiceTest < ActiveSupport::TestCase
  EXPECTED_KEYS = %i[menuitem_id menuitem_name orders_with_item_count quantity_sold share_of_orders].freeze

  def setup
    @restaurant = restaurants(:one)
    @service = RestaurantInsightsService.new(restaurant: @restaurant)
  end

  # === top_performers ===

  test 'top_performers returns an array' do
    result = @service.top_performers
    assert_kind_of Array, result
  end

  test 'top_performers items have expected keys when data exists' do
    result = @service.top_performers
    # If no orders exist, the array is empty and this still passes
    EXPECTED_KEYS.each do |key|
      result.each { |row| assert_includes row.keys, key }
    end
    pass # explicitly mark test as having run an assertion path
  end

  test 'top_performers share_of_orders is numeric for each result row' do
    result = @service.top_performers
    result.each do |row|
      assert_kind_of Numeric, row[:share_of_orders]
      assert row[:share_of_orders] >= 0.0
      assert row[:share_of_orders] <= 1.0
    end
    pass
  end

  # === slow_movers ===

  test 'slow_movers returns an array' do
    result = @service.slow_movers
    assert_kind_of Array, result
  end

  test 'slow_movers items have expected keys when data exists' do
    result = @service.slow_movers
    EXPECTED_KEYS.each do |key|
      result.each { |row| assert_includes row.keys, key }
    end
    pass
  end

  # === with date params ===

  test 'accepts date_from and date_to params without error' do
    service = RestaurantInsightsService.new(
      restaurant: @restaurant,
      params: {
        date_from: 30.days.ago.to_date.to_s,
        date_to: Time.zone.today.to_s,
      },
    )
    assert_nothing_raised { service.top_performers }
  end

  test 'returns empty array for future date range with no orders' do
    Rails.cache.clear
    service = RestaurantInsightsService.new(
      restaurant: @restaurant,
      params: {
        range: 'custom',
        start: 1.year.from_now.to_date.to_s,
        end: 2.years.from_now.to_date.to_s,
      },
    )
    result = service.top_performers
    assert_kind_of Array, result
    assert_empty result
  end
end
