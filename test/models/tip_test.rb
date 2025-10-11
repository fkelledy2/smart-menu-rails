require 'test_helper'

class TipTest < ActiveSupport::TestCase
  def setup
    @tip = tips(:one)
    @restaurant = restaurants(:one)
  end

  # === VALIDATION TESTS ===
  
  test "should be valid with valid attributes" do
    assert @tip.valid?
  end

  test "should require percentage" do
    @tip.percentage = nil
    assert_not @tip.valid?
    assert_includes @tip.errors[:percentage], "can't be blank"
  end

  test "should require numeric percentage" do
    @tip.percentage = "not_a_number"
    assert_not @tip.valid?
    assert_includes @tip.errors[:percentage], "is not a number"
  end

  test "should accept float percentage" do
    @tip.percentage = 15.5
    assert @tip.valid?
  end

  test "should accept integer percentage" do
    @tip.percentage = 20
    assert @tip.valid?
  end

  # === ASSOCIATION TESTS ===
  
  test "should belong to restaurant" do
    assert_respond_to @tip, :restaurant
    assert_instance_of Restaurant, @tip.restaurant
  end

  # === ENUM TESTS ===
  
  test "should have correct status enum values" do
    assert_equal 0, Tip.statuses[:inactive]
    assert_equal 1, Tip.statuses[:active]
    assert_equal 2, Tip.statuses[:archived]
  end

  test "should allow status changes" do
    @tip.active!
    assert @tip.active?
    
    @tip.archived!
    assert @tip.archived?
    
    @tip.inactive!
    assert @tip.inactive?
  end

  # === FACTORY/CREATION TESTS ===
  
  test "should create tip with valid data" do
    tip = Tip.new(
      percentage: 18.0,
      status: :active,
      restaurant: @restaurant
    )
    assert tip.save
    assert_equal 18.0, tip.percentage
    assert tip.active?
  end

  test "should create tip with different percentages" do
    tip = Tip.new(
      percentage: 15.0,
      status: :active,
      restaurant: @restaurant
    )
    assert tip.save
    assert_equal 15.0, tip.percentage
  end

  test "should create tip with decimal percentage" do
    tip = Tip.new(
      percentage: 12.5,
      status: :active,
      restaurant: @restaurant
    )
    assert tip.save
    assert_equal 12.5, tip.percentage
  end

  # === IDENTITY CACHE TESTS ===
  
  test "should have identity cache configured" do
    assert Tip.respond_to?(:cache_index)
  end
end
