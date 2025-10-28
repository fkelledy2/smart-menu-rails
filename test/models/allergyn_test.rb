require 'test_helper'

class AllergynTest < ActiveSupport::TestCase
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

  test 'should allow status changes' do
    @allergyn.active!
    assert @allergyn.active?

    @allergyn.archived!
    assert @allergyn.archived?

    @allergyn.inactive!
    assert @allergyn.inactive?
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

  # === DEPENDENT DESTROY TESTS ===

  test 'should have correct dependent destroy configuration' do
    reflection = Allergyn.reflect_on_association(:menuitem_allergyn_mappings)
    assert_equal :destroy, reflection.options[:dependent]

    reflection = Allergyn.reflect_on_association(:ordrparticipant_allergyn_filters)
    assert_equal :destroy, reflection.options[:dependent]
  end
end
