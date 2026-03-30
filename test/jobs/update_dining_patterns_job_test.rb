require 'test_helper'

class UpdateDiningPatternsJobTest < ActiveSupport::TestCase
  test 'perform enqueues without error for all restaurants' do
    # Smoke test: job should complete without raising
    assert_nothing_raised { UpdateDiningPatternsJob.new.perform }
  end

  test 'perform accepts restaurant_id argument' do
    restaurant = restaurants(:one)
    assert_nothing_raised { UpdateDiningPatternsJob.new.perform(restaurant_id: restaurant.id) }
  end

  test 'perform with nonexistent restaurant_id does nothing' do
    assert_nothing_raised { UpdateDiningPatternsJob.new.perform(restaurant_id: 999_999) }
  end
end
