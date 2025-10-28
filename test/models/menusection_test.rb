require 'test_helper'

class MenusectionTest < ActiveSupport::TestCase
  def setup
    @menusection = menusections(:one)
    @menu = menus(:one)
  end

  # === VALIDATION TESTS ===

  test 'should be valid with valid attributes' do
    assert @menusection.valid?
  end

  test 'should require name' do
    @menusection.name = nil
    assert_not @menusection.valid?
    assert_includes @menusection.errors[:name], "can't be blank"
  end

  test 'should require status' do
    @menusection.status = nil
    assert_not @menusection.valid?
    assert_includes @menusection.errors[:status], "can't be blank"
  end

  # === ASSOCIATION TESTS ===

  test 'should belong to menu' do
    assert_respond_to @menusection, :menu
    assert_instance_of Menu, @menusection.menu
  end

  test 'should have many menuitems' do
    assert_respond_to @menusection, :menuitems
  end

  test 'should have many menusectionlocales' do
    assert_respond_to @menusection, :menusectionlocales
  end

  test 'should have one genimage' do
    assert_respond_to @menusection, :genimage
  end

  # === ENUM TESTS ===

  test 'should have correct status enum values' do
    assert_equal 0, Menusection.statuses[:inactive]
    assert_equal 1, Menusection.statuses[:active]
    assert_equal 2, Menusection.statuses[:archived]
  end

  test 'should allow status changes' do
    @menusection.active!
    assert @menusection.active?

    @menusection.archived!
    assert @menusection.archived?

    @menusection.inactive!
    assert @menusection.inactive?
  end

  # === BUSINESS LOGIC TESTS ===

  test 'should calculate fromOffset correctly' do
    @menusection.fromhour = 9
    @menusection.frommin = 30
    assert_equal 570, @menusection.fromOffset # (9 * 60) + 30
  end

  test 'should calculate toOffset correctly' do
    @menusection.tohour = 17
    @menusection.tomin = 45
    assert_equal 1065, @menusection.toOffset # (17 * 60) + 45
  end

  test 'should handle zero time values' do
    @menusection.fromhour = 0
    @menusection.frommin = 0
    assert_equal 0, @menusection.fromOffset

    @menusection.tohour = 0
    @menusection.tomin = 0
    assert_equal 0, @menusection.toOffset
  end

  test 'should return genimage id when genimage exists' do
    assert_respond_to @menusection, :gen_image_theme
  end

  test 'should have image url methods' do
    assert_respond_to @menusection, :thumb_url
    assert_respond_to @menusection, :medium_url
    assert_respond_to @menusection, :large_url
    assert_respond_to @menusection, :image_srcset
    assert_respond_to @menusection, :image_sizes
  end

  test 'should return proper image sizes string' do
    expected_sizes = '(max-width: 600px) 200px, (max-width: 1200px) 600px, 1000px'
    assert_equal expected_sizes, @menusection.image_sizes
  end

  test 'should have localization methods' do
    assert_respond_to @menusection, :localised_name
    assert_respond_to @menusection, :localised_description
  end

  # === FACTORY/CREATION TESTS ===

  test 'should create menusection with valid data' do
    menusection = Menusection.new(
      name: 'Appetizers',
      description: 'Start your meal with these delicious appetizers',
      status: :active,
      fromhour: 11,
      frommin: 0,
      tohour: 23,
      tomin: 0,
      menu: @menu,
    )
    assert menusection.save
    assert_equal 'Appetizers', menusection.name
    assert menusection.active?
    assert_equal 660, menusection.fromOffset # 11 * 60
    assert_equal 1380, menusection.toOffset # 23 * 60
  end

  test 'should create menusection with time ranges' do
    menusection = Menusection.new(
      name: 'Lunch Specials',
      description: 'Available during lunch hours',
      status: :active,
      fromhour: 12,
      frommin: 30,
      tohour: 15,
      tomin: 30,
      menu: @menu,
    )
    assert menusection.save
    assert_equal 750, menusection.fromOffset # (12 * 60) + 30
    assert_equal 930, menusection.toOffset # (15 * 60) + 30
  end

  test 'should create inactive menusection' do
    menusection = Menusection.new(
      name: 'Seasonal Items',
      description: 'Items available seasonally',
      status: :inactive,
      menu: @menu,
    )
    assert menusection.save
    assert menusection.inactive?
  end

  # === DEPENDENT DESTROY TESTS ===

  test 'should have correct dependent destroy configuration' do
    reflection = Menusection.reflect_on_association(:genimage)
    assert_equal :destroy, reflection.options[:dependent]
  end

  # === IDENTITY CACHE TESTS ===

  test 'should have identity cache configured' do
    assert Menusection.respond_to?(:cache_index)
  end
end
