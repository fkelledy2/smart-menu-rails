require 'test_helper'

class TablesettingTest < ActiveSupport::TestCase
  def setup
    @tablesetting = tablesettings(:one)
    @restaurant = restaurants(:one)
  end

  # === VALIDATION TESTS ===

  test 'should be valid with valid attributes' do
    assert @tablesetting.valid?
  end

  test 'should require name' do
    @tablesetting.name = nil
    assert_not @tablesetting.valid?
    assert_includes @tablesetting.errors[:name], "can't be blank"
  end

  test 'should require tabletype' do
    @tablesetting.tabletype = nil
    assert_not @tablesetting.valid?
    assert_includes @tablesetting.errors[:tabletype], "can't be blank"
  end

  test 'should require capacity' do
    @tablesetting.capacity = nil
    assert_not @tablesetting.valid?
    assert_includes @tablesetting.errors[:capacity], "can't be blank"
  end

  test 'should require integer capacity' do
    @tablesetting.capacity = 4.5
    assert_not @tablesetting.valid?
    assert_includes @tablesetting.errors[:capacity], 'must be an integer'
  end

  test 'should require status' do
    @tablesetting.status = nil
    assert_not @tablesetting.valid?
    assert_includes @tablesetting.errors[:status], "can't be blank"
  end

  # === ASSOCIATION TESTS ===

  test 'should belong to restaurant' do
    assert_respond_to @tablesetting, :restaurant
    assert_instance_of Restaurant, @tablesetting.restaurant
  end

  # === ENUM TESTS ===

  test 'should have correct status enum values' do
    assert_equal 0, Tablesetting.statuses[:free]
    assert_equal 1, Tablesetting.statuses[:occupied]
    assert_equal 2, Tablesetting.statuses[:archived]
  end

  test 'should have correct tabletype enum values' do
    assert_equal 1, Tablesetting.tabletypes[:indoor]
    assert_equal 2, Tablesetting.tabletypes[:outdoor]
  end

  test 'should allow status changes' do
    @tablesetting.free!
    assert @tablesetting.free?

    @tablesetting.occupied!
    assert @tablesetting.occupied?

    @tablesetting.archived!
    assert @tablesetting.archived?
  end

  test 'should allow tabletype changes' do
    @tablesetting.indoor!
    assert @tablesetting.indoor?

    @tablesetting.outdoor!
    assert @tablesetting.outdoor?
  end

  # === FACTORY/CREATION TESTS ===

  test 'should create indoor tablesetting' do
    tablesetting = Tablesetting.new(
      name: 'Table 1',
      tabletype: :indoor,
      capacity: 4,
      status: :free,
      restaurant: @restaurant,
    )
    assert tablesetting.save
    assert_equal 'Table 1', tablesetting.name
    assert_equal 4, tablesetting.capacity
    assert tablesetting.indoor?
    assert tablesetting.free?
  end

  test 'should create outdoor tablesetting' do
    tablesetting = Tablesetting.new(
      name: 'Patio Table A',
      tabletype: :outdoor,
      capacity: 6,
      status: :free,
      restaurant: @restaurant,
    )
    assert tablesetting.save
    assert tablesetting.outdoor?
    assert_equal 6, tablesetting.capacity
  end

  test 'should create occupied tablesetting' do
    tablesetting = Tablesetting.new(
      name: 'Table 5',
      tabletype: :indoor,
      capacity: 2,
      status: :occupied,
      restaurant: @restaurant,
    )
    assert tablesetting.save
    assert tablesetting.occupied?
  end

  test 'should create tablesetting with large capacity' do
    tablesetting = Tablesetting.new(
      name: 'Banquet Table',
      tabletype: :indoor,
      capacity: 12,
      status: :free,
      restaurant: @restaurant,
    )
    assert tablesetting.save
    assert_equal 12, tablesetting.capacity
  end

  test 'should create tablesetting with single capacity' do
    tablesetting = Tablesetting.new(
      name: 'Bar Stool 1',
      tabletype: :indoor,
      capacity: 1,
      status: :free,
      restaurant: @restaurant,
    )
    assert tablesetting.save
    assert_equal 1, tablesetting.capacity
  end

  test 'should create tablesetting with description' do
    tablesetting = Tablesetting.new(
      name: 'VIP Table',
      description: 'Premium table with city view',
      tabletype: :indoor,
      capacity: 4,
      status: :free,
      restaurant: @restaurant,
    )
    assert tablesetting.save
    assert_equal 'Premium table with city view', tablesetting.description
  end

  # === BUSINESS LOGIC TESTS ===

  test 'should handle zero capacity validation' do
    tablesetting = Tablesetting.new(
      name: 'Invalid Table',
      tabletype: :indoor,
      capacity: 0,
      status: :free,
      restaurant: @restaurant,
    )
    # Capacity of 0 should be valid as an integer, but business logic might require > 0
    assert tablesetting.valid? # Basic validation passes, business rules might differ
  end

  test 'should handle negative capacity validation' do
    tablesetting = Tablesetting.new(
      name: 'Invalid Table',
      tabletype: :indoor,
      capacity: -1,
      status: :free,
      restaurant: @restaurant,
    )
    # Negative capacity should be valid as an integer, but business logic might require > 0
    assert tablesetting.valid? # Basic validation passes, business rules might differ
  end

  # === IDENTITY CACHE TESTS ===

  test 'should have identity cache configured' do
    assert Tablesetting.respond_to?(:cache_index)
  end
end
