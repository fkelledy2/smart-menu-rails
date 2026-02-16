require 'test_helper'

class MenuitemTest < ActiveSupport::TestCase
  def setup
    @menuitem = menuitems(:one)
    @menusection = menusections(:one)
  end

  # === VALIDATION TESTS ===

  test 'should be valid with valid attributes' do
    assert @menuitem.valid?
  end

  test 'should require name' do
    @menuitem.name = nil
    assert_not @menuitem.valid?
    assert_includes @menuitem.errors[:name], "can't be blank"
  end

  test 'should require itemtype' do
    @menuitem.itemtype = nil
    assert_not @menuitem.valid?
    assert_includes @menuitem.errors[:itemtype], "can't be blank"
  end

  test 'should require status' do
    @menuitem.status = nil
    assert_not @menuitem.valid?
    assert_includes @menuitem.errors[:status], "can't be blank"
  end

  test 'should require preptime' do
    @menuitem.preptime = nil
    assert_not @menuitem.valid?
    assert_includes @menuitem.errors[:preptime], "can't be blank"
  end

  test 'should require integer preptime' do
    @menuitem.preptime = 10.5
    assert_not @menuitem.valid?
    assert_includes @menuitem.errors[:preptime], 'must be an integer'
  end

  test 'should require price' do
    @menuitem.price = nil
    assert_not @menuitem.valid?
    assert_includes @menuitem.errors[:price], "can't be blank"
  end

  test 'should require numeric price' do
    @menuitem.price = 'not_a_number'
    assert_not @menuitem.valid?
    assert_includes @menuitem.errors[:price], 'is not a number'
  end

  test 'should require calories' do
    @menuitem.calories = nil
    assert_not @menuitem.valid?
    assert_includes @menuitem.errors[:calories], "can't be blank"
  end

  test 'should require integer calories' do
    @menuitem.calories = 250.5
    assert_not @menuitem.valid?
    assert_includes @menuitem.errors[:calories], 'must be an integer'
  end

  test 'should not require inventory' do
    @menuitem.inventory = nil
    assert @menuitem.valid?
  end

  # === ASSOCIATION TESTS ===

  test 'should belong to menusection' do
    assert_respond_to @menuitem, :menusection
    assert_instance_of Menusection, @menuitem.menusection
  end

  test 'should have many menuitemlocales' do
    assert_respond_to @menuitem, :menuitemlocales
  end

  test 'should have many allergyns through mappings' do
    assert_respond_to @menuitem, :allergyns
  end

  test 'should have many tags through mappings' do
    assert_respond_to @menuitem, :tags
  end

  test 'should have many sizes through mappings' do
    assert_respond_to @menuitem, :sizes
  end

  test 'should have many ingredients through mappings' do
    assert_respond_to @menuitem, :ingredients
  end

  test 'should have many ordritems' do
    assert_respond_to @menuitem, :ordritems
  end

  test 'should have one inventory' do
    assert_respond_to @menuitem, :inventory
  end

  test 'should have one genimage' do
    assert_respond_to @menuitem, :genimage
  end

  # === ENUM TESTS ===

  test 'should have correct status enum values' do
    assert_equal 0, Menuitem.statuses[:inactive]
    assert_equal 1, Menuitem.statuses[:active]
    assert_equal 2, Menuitem.statuses[:archived]
  end

  test 'should have correct itemtype enum values' do
    assert_equal 0, Menuitem.itemtypes[:food]
    assert_equal 1, Menuitem.itemtypes[:beverage]
    assert_equal 2, Menuitem.itemtypes[:wine]
  end

  test 'should allow status changes' do
    @menuitem.active!
    assert @menuitem.active?

    @menuitem.archived!
    assert @menuitem.archived?

    @menuitem.inactive!
    assert @menuitem.inactive?
  end

  test 'should allow itemtype changes' do
    @menuitem.food!
    assert @menuitem.food?

    @menuitem.beverage!
    assert @menuitem.beverage?

    @menuitem.wine!
    assert @menuitem.wine?
  end

  # === BUSINESS LOGIC TESTS ===

  test 'should return genimage id when genimage exists' do
    # This would require setting up a genimage association
    assert_respond_to @menuitem, :genImageId
  end

  test 'should return -1 when genimage does not exist' do
    @menuitem.genimage = nil
    assert_equal(-1, @menuitem.genImageId)
  end

  test 'should have image url methods' do
    assert_respond_to @menuitem, :thumb_url
    assert_respond_to @menuitem, :medium_url
    assert_respond_to @menuitem, :large_url
    assert_respond_to @menuitem, :image_srcset
    assert_respond_to @menuitem, :image_sizes
  end

  test 'should return proper image sizes string' do
    expected_sizes = '(max-width: 480px) 150px, (max-width: 768px) 200px, (max-width: 1200px) 600px, 1000px'
    assert_equal expected_sizes, @menuitem.image_sizes
  end

  # === FACTORY/CREATION TESTS ===

  test 'should create menuitem with valid data' do
    menuitem = Menuitem.new(
      name: 'Margherita Pizza',
      description: 'Classic pizza with tomato and mozzarella',
      price: 12.99,
      preptime: 15,
      calories: 800,
      itemtype: :food,
      status: :active,
      menusection: @menusection,
    )
    assert menuitem.save
    assert_equal 'Margherita Pizza', menuitem.name
    assert_equal 12.99, menuitem.price
    assert_equal 15, menuitem.preptime
    assert_equal 800, menuitem.calories
    assert menuitem.food?
    assert menuitem.active?
  end

  test 'should create beverage menuitem' do
    menuitem = Menuitem.new(
      name: 'Coca Cola',
      description: 'Refreshing soft drink',
      price: 2.99,
      preptime: 1,
      calories: 150,
      itemtype: :beverage,
      status: :active,
      menusection: @menusection,
    )
    assert menuitem.save
    assert menuitem.beverage?
  end

  test 'should create wine menuitem' do
    menuitem = Menuitem.new(
      name: 'Chianti Classico',
      description: 'Italian red wine',
      price: 8.99,
      preptime: 2,
      calories: 125,
      itemtype: :wine,
      status: :active,
      menusection: @menusection,
    )
    assert menuitem.save
    assert menuitem.wine?
  end

  # === DEPENDENT DESTROY TESTS ===

  test 'should have correct dependent destroy configuration' do
    reflection = Menuitem.reflect_on_association(:menuitem_allergyn_mappings)
    assert_equal :destroy, reflection.options[:dependent]

    reflection = Menuitem.reflect_on_association(:menuitem_tag_mappings)
    assert_equal :destroy, reflection.options[:dependent]

    reflection = Menuitem.reflect_on_association(:ordritems)
    assert_equal :destroy, reflection.options[:dependent]
  end

  # === IDENTITY CACHE TESTS ===

  test 'should have identity cache configured' do
    assert Menuitem.respond_to?(:cache_index)
  end

  # === COMPLEX VALIDATION TESTS - EDGE CASES ===

  test 'should accept zero price for free items' do
    @menuitem.price = 0.0
    assert @menuitem.valid?
  end

  test 'should reject negative price' do
    @menuitem.price = -1.0
    assert_not @menuitem.valid?
    assert_includes @menuitem.errors[:price], 'must be greater than or equal to 0'
  end

  test 'should accept very high price' do
    @menuitem.price = 999_999.99
    assert @menuitem.valid?
  end

  test 'should accept zero preptime' do
    @menuitem.preptime = 0
    assert @menuitem.valid?
  end

  test 'should reject negative preptime' do
    @menuitem.preptime = -1
    assert_not @menuitem.valid?
    assert_includes @menuitem.errors[:preptime], 'must be greater than or equal to 0'
  end

  test 'should accept very high preptime' do
    @menuitem.preptime = 999
    assert @menuitem.valid?
  end

  test 'should accept zero calories' do
    @menuitem.calories = 0
    assert @menuitem.valid?
  end

  test 'should reject negative calories' do
    @menuitem.calories = -1
    assert_not @menuitem.valid?
    assert_includes @menuitem.errors[:calories], 'must be greater than or equal to 0'
  end

  test 'should accept very high calories' do
    @menuitem.calories = 9999
    assert @menuitem.valid?
  end

  test 'should reject string for price' do
    @menuitem.price = 'abc'
    assert_not @menuitem.valid?
    assert_includes @menuitem.errors[:price], 'is not a number'
  end

  test 'should reject string for preptime' do
    @menuitem.preptime = 'abc'
    assert_not @menuitem.valid?
    assert_includes @menuitem.errors[:preptime], 'is not a number'
  end

  test 'should reject string for calories' do
    @menuitem.calories = 'abc'
    assert_not @menuitem.valid?
    assert_includes @menuitem.errors[:calories], 'is not a number'
  end

  test 'should reject float for preptime' do
    @menuitem.preptime = 10.5
    assert_not @menuitem.valid?
    assert_includes @menuitem.errors[:preptime], 'must be an integer'
  end

  test 'should reject float for calories' do
    @menuitem.calories = 250.5
    assert_not @menuitem.valid?
    assert_includes @menuitem.errors[:calories], 'must be an integer'
  end

  test 'should accept float for price' do
    @menuitem.price = 12.99
    assert @menuitem.valid?
  end

  test 'should accept integer for price' do
    @menuitem.price = 12
    assert @menuitem.valid?
  end

  test 'should accept empty string name as invalid' do
    @menuitem.name = ''
    assert_not @menuitem.valid?
    assert_includes @menuitem.errors[:name], "can't be blank"
  end

  test 'should accept very long name' do
    @menuitem.name = 'A' * 255
    assert @menuitem.valid?
  end

  test 'should accept unicode in name' do
    @menuitem.name = 'Crème Brûlée 🍮'
    assert @menuitem.valid?
  end

  test 'should accept special characters in name' do
    @menuitem.name = "Chef's Special (Spicy!)"
    assert @menuitem.valid?
  end

  test 'should handle nil description' do
    @menuitem.description = nil
    assert @menuitem.valid?
  end

  test 'should handle empty description' do
    @menuitem.description = ''
    assert @menuitem.valid?
  end

  test 'should handle very long description' do
    @menuitem.description = 'A' * 5000
    assert @menuitem.valid?
  end

  # === BUSINESS RULE VALIDATION TESTS ===

  test 'should allow status transition from inactive to active' do
    @menuitem.inactive!
    @menuitem.active!
    assert @menuitem.active?
  end

  test 'should allow status transition from active to archived' do
    @menuitem.active!
    @menuitem.archived!
    assert @menuitem.archived?
  end

  test 'should allow status transition from archived to active' do
    @menuitem.archived!
    @menuitem.active!
    assert @menuitem.active?
  end

  test 'should maintain price precision' do
    @menuitem.price = 12.99
    @menuitem.save!
    @menuitem.reload
    assert_equal 12.99, @menuitem.price
  end

  test 'should handle price with many decimal places' do
    @menuitem.price = 12.999999
    assert @menuitem.valid?
  end

  test 'should create with minimum required fields' do
    menuitem = Menuitem.new(
      name: 'Test Item',
      price: 1.0,
      preptime: 1,
      calories: 1,
      itemtype: :food,
      status: :active,
      menusection: @menusection,
    )
    assert menuitem.valid?
    assert menuitem.save
  end

  test 'should fail without menusection' do
    menuitem = Menuitem.new(
      name: 'Test Item',
      price: 1.0,
      preptime: 1,
      calories: 1,
      itemtype: :food,
      status: :active,
    )
    assert_not menuitem.valid?
    assert_includes menuitem.errors[:menusection], 'must exist'
  end

  test 'should handle multiple validation errors' do
    menuitem = Menuitem.new(
      name: nil,
      price: -1.0,
      preptime: -1,
      calories: -1,
      itemtype: nil,
      status: nil,
    )
    assert_not menuitem.valid?
    assert menuitem.errors[:name].any?
    assert menuitem.errors[:price].any?
    assert menuitem.errors[:preptime].any?
    assert menuitem.errors[:calories].any?
    assert menuitem.errors[:itemtype].any?
    assert menuitem.errors[:status].any?
  end

  test 'should validate all numeric fields simultaneously' do
    menuitem = Menuitem.new(
      name: 'Test',
      price: 'abc',
      preptime: 'def',
      calories: 'ghi',
      itemtype: :food,
      status: :active,
      menusection: @menusection,
    )
    assert_not menuitem.valid?
    assert_includes menuitem.errors[:price], 'is not a number'
    assert_includes menuitem.errors[:preptime], 'is not a number'
    assert_includes menuitem.errors[:calories], 'is not a number'
  end
end
