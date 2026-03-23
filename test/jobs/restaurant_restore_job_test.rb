# frozen_string_literal: true

require 'test_helper'

class RestaurantRestoreJobTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
    @user = users(:one)
    # Archive first so we can test restore
    @restaurant.update_column(:archived, true)
  end

  test 'restores a restaurant by id (keyword args)' do
    RestaurantRestoreJob.new.perform(
      restaurant_id: @restaurant.id,
      archived_by_id: @user.id,
      reason: 'test restore',
    )

    @restaurant.reload
    assert_equal false, @restaurant.archived
  end

  test 'restores a restaurant by id (positional args)' do
    RestaurantRestoreJob.new.perform(@restaurant.id, @user.id, 'positional restore')

    @restaurant.reload
    assert_equal false, @restaurant.archived
  end

  test 'does nothing when restaurant_id does not exist' do
    assert_nothing_raised do
      RestaurantRestoreJob.new.perform(restaurant_id: -999_999)
    end
  end

  test 'enqueues asynchronously without raising' do
    assert_nothing_raised do
      RestaurantRestoreJob.perform_later(restaurant_id: @restaurant.id)
    end
  end
end
