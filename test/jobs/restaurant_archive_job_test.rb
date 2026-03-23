# frozen_string_literal: true

require 'test_helper'

class RestaurantArchiveJobTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
    @user = users(:one)
    # Ensure restaurant is not archived before each test
    @restaurant.update_column(:archived, false)
  end

  test 'archives a restaurant by id (keyword args)' do
    RestaurantArchiveJob.new.perform(
      restaurant_id: @restaurant.id,
      archived_by_id: @user.id,
      reason: 'test archive',
    )

    @restaurant.reload
    assert @restaurant.archived
  end

  test 'archives a restaurant by id (positional args)' do
    RestaurantArchiveJob.new.perform(@restaurant.id, @user.id, 'positional reason')

    @restaurant.reload
    assert @restaurant.archived
  end

  test 'does nothing when restaurant_id does not exist' do
    assert_nothing_raised do
      RestaurantArchiveJob.new.perform(restaurant_id: -999_999)
    end
  end

  test 'enqueues asynchronously without raising' do
    assert_nothing_raised do
      RestaurantArchiveJob.perform_later(restaurant_id: @restaurant.id)
    end
  end
end
