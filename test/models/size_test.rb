require 'test_helper'

class SizeTest < ActiveSupport::TestCase
  def setup
    @size = sizes(:one)
    @restaurant = restaurants(:one)
  end

  # === VALIDATION TESTS ===
  
  test "should be valid with valid attributes" do
    assert @size.valid?
  end

  test "should require name" do
    @size.name = nil
    assert_not @size.valid?
    assert_includes @size.errors[:name], "can't be blank"
  end

  test "should require size" do
    @size.size = nil
    assert_not @size.valid?
    assert_includes @size.errors[:size], "can't be blank"
  end

  # === ASSOCIATION TESTS ===
  
  test "should belong to restaurant" do
    assert_respond_to @size, :restaurant
    assert_instance_of Restaurant, @size.restaurant
  end

  test "should have many menuitem_size_mappings" do
    assert_respond_to @size, :menuitem_size_mappings
  end

  test "should have many menuitems through mappings" do
    assert_respond_to @size, :menuitems
  end

  # === ENUM TESTS ===
  
  test "should have correct size enum values" do
    assert_equal 0, Size.sizes[:xs]
    assert_equal 1, Size.sizes[:sm]
    assert_equal 2, Size.sizes[:md]
    assert_equal 3, Size.sizes[:lg]
    assert_equal 4, Size.sizes[:xl]
  end

  test "should have correct status enum values" do
    assert_equal 0, Size.statuses[:inactive]
    assert_equal 1, Size.statuses[:active]
    assert_equal 2, Size.statuses[:archived]
  end

  test "should allow size changes" do
    @size.sm!
    assert @size.sm?
    
    @size.lg!
    assert @size.lg?
  end

  test "should allow status changes" do
    @size.active!
    assert @size.active?
    
    @size.archived!
    assert @size.archived?
  end

  # === FACTORY/CREATION TESTS ===
  
  test "should create size with valid data" do
    size = Size.new(
      name: "Large",
      size: :lg,
      restaurant: @restaurant,
      status: :active
    )
    assert size.save
    assert_equal "Large", size.name
    assert size.lg?
    assert size.active?
  end

  # === DEPENDENT DESTROY TESTS ===
  
  test "should have correct dependent destroy configuration" do
    reflection = Size.reflect_on_association(:menuitem_size_mappings)
    assert_equal :destroy, reflection.options[:dependent]
  end
end
