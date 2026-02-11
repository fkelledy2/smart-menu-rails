require 'test_helper'

class RestaurantRemovalRequestTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
    @restaurant.update_columns(claim_status: 0, preview_enabled: true, preview_published_at: Time.current)
  end

  test 'valid removal request saves' do
    rr = RestaurantRemovalRequest.new(
      restaurant: @restaurant,
      requested_by_email: 'owner@example.com',
      source: :public_page,
      status: :received,
      reason: 'Please remove my restaurant',
    )
    assert rr.valid?, rr.errors.full_messages.join(', ')
    assert rr.save
  end

  test 'requires requested_by_email' do
    rr = RestaurantRemovalRequest.new(
      restaurant: @restaurant,
      source: :public_page,
      status: :received,
    )
    assert_not rr.valid?
    assert_includes rr.errors[:requested_by_email], "can't be blank"
  end

  test 'enum statuses' do
    rr = RestaurantRemovalRequest.new(restaurant: @restaurant, requested_by_email: 'a@b.com', source: :public_page)
    %i[received actioned_unpublished resolved].each do |s|
      rr.status = s
      assert rr.send("#{s}?"), "Expected #{s}? to be true"
    end
  end

  test 'action_unpublish! disables preview and updates status' do
    rr = RestaurantRemovalRequest.create!(
      restaurant: @restaurant,
      requested_by_email: 'owner@example.com',
      source: :public_page,
      status: :received,
      reason: 'Remove please',
    )

    rr.action_unpublish!(user: users(:one))

    assert rr.actioned_unpublished?
    assert rr.actioned_at.present?
    @restaurant.reload
    assert_not @restaurant.preview_enabled?
  end
end
