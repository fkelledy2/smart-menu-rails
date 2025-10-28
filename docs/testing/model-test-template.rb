# Model Test Template - Example: Allergyn
# Copy this pattern for other models

require 'test_helper'

class AllergynTest < ActiveSupport::TestCase
  # Setup - use fixtures
  def setup
    @allergyn = allergyns(:one)
    @restaurant = restaurants(:one)
  end

  # === VALIDATION TESTS ===

  test 'should be valid with valid attributes' do
    assert @allergyn.valid?
  end

  test 'should require name' do
    @allergyn.name = nil
    assert_not @allergyn.valid?
    assert_includes @allergyn.errors[:name], "can't be blank"
  end

  test 'should require symbol' do
    @allergyn.symbol = nil
    assert_not @allergyn.valid?
    assert_includes @allergyn.errors[:symbol], "can't be blank"
  end

  # === ASSOCIATION TESTS ===

  test 'should belong to restaurant' do
    assert_respond_to @allergyn, :restaurant
    assert_instance_of Restaurant, @allergyn.restaurant
  end

  test 'should have many menuitem_allergyn_mappings' do
    assert_respond_to @allergyn, :menuitem_allergyn_mappings
  end

  test 'should have many menuitems through mappings' do
    assert_respond_to @allergyn, :menuitems
  end

  test 'should have many ordrparticipant_allergyn_filters' do
    assert_respond_to @allergyn, :ordrparticipant_allergyn_filters
  end

  test 'should have many ordrparticipants through filters' do
    assert_respond_to @allergyn, :ordrparticipants
  end

  # === ENUM TESTS ===

  test 'should have correct status enum values' do
    assert_equal 0, Allergyn.statuses[:inactive]
    assert_equal 1, Allergyn.statuses[:active]
    assert_equal 2, Allergyn.statuses[:archived]
  end

  test 'should default to inactive status' do
    new_allergyn = Allergyn.new(name: 'Test', symbol: 'T', restaurant: @restaurant)
    assert_equal 'inactive', new_allergyn.status
  end

  test 'should allow status changes' do
    @allergyn.active!
    assert @allergyn.active?

    @allergyn.archived!
    assert @allergyn.archived?
  end

  # === IDENTITY CACHE TESTS ===

  test 'should have identity cache configured' do
    assert Allergyn.respond_to?(:cache_index)
  end

  # === DEPENDENT DESTROY TESTS ===

  test 'should destroy associated mappings when destroyed' do
    # This would require setting up actual associations in fixtures
    # For now, just test the association is configured correctly
    reflection = Allergyn.reflect_on_association(:menuitem_allergyn_mappings)
    assert_equal :destroy, reflection.options[:dependent]
  end

  # === FACTORY/CREATION TESTS ===

  test 'should create allergyn with valid factory data' do
    allergyn = Allergyn.new(
      name: 'Gluten',
      symbol: 'G',
      restaurant: @restaurant,
      status: :active,
    )
    assert allergyn.save
    assert_equal 'Gluten', allergyn.name
    assert_equal 'G', allergyn.symbol
    assert allergyn.active?
  end
end

# === COVERAGE IMPACT ===
# This test file should cover:
# - All validations (name, symbol presence)
# - All associations (restaurant, mappings, through associations)
# - All enum values and methods
# - Basic model creation and attribute assignment
# - Dependent destroy configuration
#
# Expected coverage increase: 2-3% for this model alone
