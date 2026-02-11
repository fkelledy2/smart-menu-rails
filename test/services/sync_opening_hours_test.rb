require 'test_helper'

class SyncOpeningHoursTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
    @restaurant.update_columns(claim_status: 0) # unclaimed
    @restaurant.restaurantavailabilities.destroy_all

    @discovered = DiscoveredRestaurant.create!(
      name: 'Test Restaurant',
      city_name: 'Dublin',
      google_place_id: "test_place_#{SecureRandom.hex(4)}",
      status: :approved,
      restaurant: @restaurant,
      metadata: {
        'place_details' => {
          'opening_hours' => [
            { 'day' => 1, 'open_hour' => 9, 'open_min' => 0, 'close_hour' => 22, 'close_min' => 0 },
            { 'day' => 2, 'open_hour' => 9, 'open_min' => 0, 'close_hour' => 22, 'close_min' => 0 },
            { 'day' => 3, 'open_hour' => 9, 'open_min' => 0, 'close_hour' => 22, 'close_min' => 0 },
            { 'day' => 4, 'open_hour' => 9, 'open_min' => 0, 'close_hour' => 22, 'close_min' => 0 },
            { 'day' => 5, 'open_hour' => 11, 'open_min' => 30, 'close_hour' => 23, 'close_min' => 30 },
            { 'day' => 6, 'open_hour' => 11, 'open_min' => 30, 'close_hour' => 23, 'close_min' => 30 },
          ],
        },
      },
    )
  end

  test 'sync_opening_hours! creates restaurantavailabilities for each day' do
    service = DiscoveredRestaurantRestaurantSyncService.new(
      discovered_restaurant: @discovered,
      restaurant: @restaurant,
    )
    service.sync!

    @restaurant.reload
    availabilities = @restaurant.restaurantavailabilities.order(:dayofweek)

    # 6 open days + 1 closed day (Sunday) = 7 total
    assert_equal 7, availabilities.count

    # Monday (day 1) should be open 09:00-22:00
    monday = availabilities.find(&:monday?)
    assert monday.present?, 'Monday availability should exist'
    assert monday.open?
    assert_equal 9, monday.starthour
    assert_equal 0, monday.startmin
    assert_equal 22, monday.endhour
    assert_equal 0, monday.endmin

    # Friday (day 5) should be open 11:30-23:30
    friday = availabilities.find(&:friday?)
    assert friday.present?, 'Friday availability should exist'
    assert friday.open?
    assert_equal 11, friday.starthour
    assert_equal 30, friday.startmin
    assert_equal 23, friday.endhour
    assert_equal 30, friday.endmin

    # Sunday (day 0) not in the data → should be closed
    sunday = availabilities.find(&:sunday?)
    assert sunday.present?, 'Sunday availability should exist'
    assert sunday.closed?
  end

  test 'sync_opening_hours! does not overwrite hours on claimed restaurants' do
    @restaurant.update_columns(claim_status: 2) # claimed
    # Create existing manual hours
    @restaurant.restaurantavailabilities.create!(
      dayofweek: :monday, starthour: 8, startmin: 0, endhour: 20, endmin: 0, status: :open, sequence: 1,
    )

    service = DiscoveredRestaurantRestaurantSyncService.new(
      discovered_restaurant: @discovered,
      restaurant: @restaurant,
    )
    service.sync!

    @restaurant.reload
    monday = @restaurant.restaurantavailabilities.find_by(dayofweek: :monday)
    # Should still have the manual hours, not the Google hours
    assert_equal 8, monday.starthour
    assert_equal 20, monday.endhour
  end

  test 'sync_opening_hours! updates existing hours on unclaimed restaurants' do
    # Create old hours
    @restaurant.restaurantavailabilities.create!(
      dayofweek: :monday, starthour: 8, startmin: 0, endhour: 18, endmin: 0, status: :open, sequence: 1,
    )

    service = DiscoveredRestaurantRestaurantSyncService.new(
      discovered_restaurant: @discovered,
      restaurant: @restaurant,
    )
    service.sync!

    @restaurant.reload
    monday = @restaurant.restaurantavailabilities.find_by(dayofweek: :monday, sequence: 1)
    # Should be updated to Google hours
    assert_equal 9, monday.starthour
    assert_equal 22, monday.endhour
  end

  test 'sync_opening_hours! handles missing opening_hours gracefully' do
    @discovered.update!(metadata: { 'place_details' => {} })

    service = DiscoveredRestaurantRestaurantSyncService.new(
      discovered_restaurant: @discovered,
      restaurant: @restaurant,
    )
    # Should not raise
    service.sync!
    assert_equal 0, @restaurant.restaurantavailabilities.count
  end
end
