require 'test_helper'

class RestaurantMenuTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
    @menu = menus(:one)
    @rm = RestaurantMenu.new(
      restaurant: @restaurant,
      menu: @menu,
      status: :active,
      availability_state: :available,
    )
  end

  test 'valid record saves' do
    assert @rm.save
  end

  test 'requires status' do
    @rm.status = nil
    assert_not @rm.valid?
  end

  test 'requires availability_state' do
    @rm.availability_state = nil
    assert_not @rm.valid?
  end

  test 'enforces unique menu per restaurant' do
    @rm.save!
    duplicate = RestaurantMenu.new(restaurant: @restaurant, menu: @menu, status: :active, availability_state: :available)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:menu_id], 'has already been taken'
  end

  test 'active status enum works' do
    @rm.status = :active
    assert @rm.active?
  end

  test 'inactive status enum works' do
    @rm.status = :inactive
    assert @rm.inactive?
  end

  test 'archived status enum works' do
    @rm.status = :archived
    assert @rm.archived?
  end

  test 'available availability_state enum works' do
    @rm.availability_state = :available
    assert @rm.available?
  end

  test 'unavailable availability_state enum works' do
    @rm.availability_state = :unavailable
    assert @rm.unavailable?
  end

  test 'effective_available? returns true when override disabled' do
    @rm.availability_override_enabled = false
    assert @rm.effective_available?
  end

  test 'effective_available? respects availability_state when override enabled' do
    @rm.availability_override_enabled = true
    @rm.availability_state = :available
    assert @rm.effective_available?

    @rm.availability_state = :unavailable
    assert_not @rm.effective_available?
  end
end
