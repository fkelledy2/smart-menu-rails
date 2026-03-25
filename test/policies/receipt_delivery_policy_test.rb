require 'test_helper'

class ReceiptDeliveryPolicyTest < ActiveSupport::TestCase
  def setup
    @owner = users(:one)
    @other_user = users(:two)
    @employee_user = users(:one) # employee fixture belongs to restaurant :one / user :one
    @super_admin = users(:super_admin)

    @ordr = ordrs(:one)
    @restaurant = restaurants(:one)

    @delivery = ReceiptDelivery.new(ordr: @ordr, restaurant: @restaurant)
  end

  # ---------------------------------------------------------------------------
  # create?
  # ---------------------------------------------------------------------------

  test 'create? is allowed for the restaurant owner' do
    assert ReceiptDeliveryPolicy.new(@owner, @delivery).create?
  end

  test 'create? is denied for a user who does not own the restaurant' do
    assert_not ReceiptDeliveryPolicy.new(@other_user, @delivery).create?
  end

  test 'create? is denied for a guest (nil user)' do
    assert_not ReceiptDeliveryPolicy.new(nil, @delivery).create?
  end

  test 'create? is allowed for super_admin' do
    assert ReceiptDeliveryPolicy.new(@super_admin, @delivery).create?
  end

  # ---------------------------------------------------------------------------
  # index? / show?
  # ---------------------------------------------------------------------------

  test 'index? is allowed for restaurant owner' do
    assert ReceiptDeliveryPolicy.new(@owner, @delivery).index?
  end

  test 'index? is denied for non-owner' do
    assert_not ReceiptDeliveryPolicy.new(@other_user, @delivery).index?
  end

  test 'show? is allowed for restaurant owner' do
    assert ReceiptDeliveryPolicy.new(@owner, @delivery).show?
  end

  test 'show? is denied for non-owner' do
    assert_not ReceiptDeliveryPolicy.new(@other_user, @delivery).show?
  end

  # ---------------------------------------------------------------------------
  # self_service?
  # ---------------------------------------------------------------------------

  test 'self_service? is allowed for anyone' do
    assert ReceiptDeliveryPolicy.new(nil, @delivery).self_service?
    assert ReceiptDeliveryPolicy.new(@owner, @delivery).self_service?
    assert ReceiptDeliveryPolicy.new(@other_user, @delivery).self_service?
  end

  # ---------------------------------------------------------------------------
  # Scope
  # ---------------------------------------------------------------------------

  test 'scope returns deliveries for restaurants owned by user' do
    ReceiptDelivery.create!(
      ordr: @ordr,
      restaurant: @restaurant,
      recipient_email: 'scope_test@example.com',
      delivery_method: 'email',
    )

    scope = ReceiptDeliveryPolicy::Scope.new(@owner, ReceiptDelivery).resolve
    assert(scope.any? { |d| d.restaurant_id == @restaurant.id })
  end

  test 'scope excludes deliveries for restaurants not owned by user' do
    scope = ReceiptDeliveryPolicy::Scope.new(@other_user, ReceiptDelivery).resolve
    # restaurant :two belongs to user :two — user :one should not see restaurant :one deliveries
    assert(scope.none? { |d| d.restaurant_id == @restaurant.id })
  end

  test 'scope returns all deliveries for super_admin' do
    scope = ReceiptDeliveryPolicy::Scope.new(@super_admin, ReceiptDelivery).resolve
    assert_equal ReceiptDelivery.count, scope.count
  end
end
