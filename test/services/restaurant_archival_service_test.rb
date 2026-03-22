require 'test_helper'

class RestaurantArchivalServiceTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
    @user = users(:one)
  end

  # === archive! ===

  test 'archive! marks restaurant as archived' do
    @restaurant.update!(archived: false)

    RestaurantArchivalService.archive!(
      restaurant: @restaurant,
      archived_by_id: @user.id,
      reason: 'Test archival',
    )

    @restaurant.reload
    assert @restaurant.archived
  end

  test 'archive! is idempotent when already archived' do
    @restaurant.update!(archived: true)

    # Should not raise and should return without updating
    assert_nothing_raised do
      RestaurantArchivalService.archive!(restaurant: @restaurant)
    end
  end

  test 'archive! sets archived_at timestamp' do
    @restaurant.update!(archived: false)
    freeze_time = Time.current

    RestaurantArchivalService.archive!(restaurant: @restaurant, archived_at: freeze_time)

    @restaurant.reload
    assert_in_delta freeze_time.to_i, @restaurant.archived_at.to_i, 1
  end

  # === restore! ===

  test 'restore! un-archives a restaurant' do
    @restaurant.update!(archived: true)

    RestaurantArchivalService.restore!(
      restaurant: @restaurant,
      archived_by_id: @user.id,
    )

    @restaurant.reload
    assert_not @restaurant.archived
  end

  test 'restore! is idempotent when not archived' do
    @restaurant.update!(archived: false)

    assert_nothing_raised do
      RestaurantArchivalService.restore!(restaurant: @restaurant)
    end
  end

  test 'restore! clears archived_at' do
    @restaurant.update!(archived: true, archived_at: 1.day.ago)

    RestaurantArchivalService.restore!(restaurant: @restaurant)

    @restaurant.reload
    assert_nil @restaurant.archived_at
  end

  # === archive/restore round-trip ===

  test 'archive then restore returns restaurant to original state' do
    @restaurant.update!(archived: false)

    RestaurantArchivalService.archive!(restaurant: @restaurant, reason: 'temporary')
    @restaurant.reload
    assert @restaurant.archived

    RestaurantArchivalService.restore!(restaurant: @restaurant)
    @restaurant.reload
    assert_not @restaurant.archived
  end
end
