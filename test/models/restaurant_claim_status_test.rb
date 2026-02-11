require 'test_helper'

class RestaurantClaimStatusTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
  end

  test 'claim_status defaults and transitions' do
    @restaurant.update_columns(claim_status: 0)
    @restaurant.reload
    assert @restaurant.unclaimed?

    @restaurant.update!(claim_status: :soft_claimed)
    assert @restaurant.soft_claimed?

    @restaurant.update!(claim_status: :claimed)
    assert @restaurant.claimed?

    @restaurant.update!(claim_status: :verified)
    assert @restaurant.verified?
  end

  test 'provisioned_by enum' do
    @restaurant.update!(provisioned_by: :provisioned_by_owner)
    assert @restaurant.provisioned_provisioned_by_owner?

    @restaurant.update!(provisioned_by: :provisioned_by_system)
    assert @restaurant.provisioned_provisioned_by_system?
  end

  test 'preview_published? requires both preview_enabled and preview_published_at' do
    @restaurant.update_columns(preview_enabled: false, preview_published_at: nil)
    assert_not @restaurant.preview_published?

    @restaurant.update_columns(preview_enabled: true, preview_published_at: nil)
    assert_not @restaurant.preview_published?

    @restaurant.update_columns(preview_enabled: true, preview_published_at: Time.current)
    assert @restaurant.preview_published?
  end

  test 'ordering_enabled and payments_enabled default to false' do
    r = Restaurant.new
    assert_not r.ordering_enabled?
    assert_not r.payments_enabled?
  end

  test 'has_many restaurant_claim_requests' do
    assert_respond_to @restaurant, :restaurant_claim_requests
  end

  test 'has_many restaurant_removal_requests' do
    assert_respond_to @restaurant, :restaurant_removal_requests
  end
end
