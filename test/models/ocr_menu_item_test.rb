require 'test_helper'

class OcrMenuItemTest < ActiveSupport::TestCase
  include OcrMenuImportsTestHelper

  setup do
    @restaurant = restaurants(:one)
    @ocr_menu_import = OcrMenuImport.create!(
      restaurant: @restaurant,
      name: 'Test Menu Import',
      status: :completed,
    )

    @ocr_menu_section = OcrMenuSection.create!(
      ocr_menu_import: @ocr_menu_import,
      name: 'Starters',
      description: 'Delicious starters to begin your meal',
      position: 1,
    )

    @ocr_menu_item = OcrMenuItem.new(
      ocr_menu_section: @ocr_menu_section,
      name: 'Bruschetta',
      description: 'Toasted bread with tomatoes, garlic and basil',
      price: 8.99,
      position: 1,
      allergens: ['gluten'],
      dietary_restrictions: ['vegetarian'],
    )
  end

  test 'should be valid with valid attributes' do
    assert @ocr_menu_item.valid?
  end

  test 'should require an ocr_menu_section' do
    @ocr_menu_item.ocr_menu_section = nil
    assert_not @ocr_menu_item.valid?
    assert_includes @ocr_menu_item.errors[:ocr_menu_section], 'must exist'
  end

  test 'should require a name' do
    @ocr_menu_item.name = nil
    assert_not @ocr_menu_item.valid?
    assert_includes @ocr_menu_item.errors[:name], "can't be blank"
  end

  test 'should not require a price' do
    @ocr_menu_item.price = nil
    assert @ocr_menu_item.valid?
  end

  test 'should have a default position' do
    item = OcrMenuItem.new(
      ocr_menu_section: @ocr_menu_section,
      name: 'Calamari',
      description: 'Fried squid with marinara sauce',
      price: 12.99,
    )
    assert item.valid?
    assert_not_nil item.position
  end

  test 'should have a default status of pending' do
    item = OcrMenuItem.new(
      ocr_menu_section: @ocr_menu_section,
      name: 'Calamari',
      description: 'Fried squid with marinara sauce',
    )
    assert_equal 'pending', item.status
  end

  test 'should be orderable by position' do
    # Create items in reverse order
    OcrMenuItem.create!(
      ocr_menu_section: @ocr_menu_section,
      name: 'Garlic Bread',
      description: 'Toasted bread with garlic and herbs',
      price: 5.99,
      position: 3,
    )

    OcrMenuItem.create!(
      ocr_menu_section: @ocr_menu_section,
      name: 'Calamari',
      description: 'Fried squid with marinara sauce',
      price: 12.99,
      position: 2,
    )

    OcrMenuItem.create!(
      ocr_menu_section: @ocr_menu_section,
      name: 'Bruschetta',
      description: 'Toasted bread with tomatoes, garlic and basil',
      price: 8.99,
      position: 1,
    )

    # Should be ordered by position
    assert_equal ['Bruschetta', 'Calamari', 'Garlic Bread'],
                 @ocr_menu_section.ocr_menu_items.ordered.pluck(:name)
  end

  test 'should serialize and deserialize allergens' do
    allergens = %w[gluten dairy]
    @ocr_menu_item.allergens = allergens
    @ocr_menu_item.save!

    item = OcrMenuItem.find(@ocr_menu_item.id)
    assert_equal allergens, item.allergens
  end

  test 'should serialize and deserialize dietary_restrictions' do
    dietary_restrictions = %w[vegetarian vegan]
    @ocr_menu_item.dietary_restrictions = dietary_restrictions
    @ocr_menu_item.save!

    item = OcrMenuItem.find(@ocr_menu_item.id)
    assert_equal dietary_restrictions, item.dietary_restrictions
  end

  test 'should mark as confirmed' do
    @ocr_menu_item.save!
    @ocr_menu_item.confirm!

    assert @ocr_menu_item.confirmed?
    assert_not_nil @ocr_menu_item.confirmed_at
  end

  test 'should return formatted price' do
    @ocr_menu_item.price = 8.99
    assert_equal '$8.99', @ocr_menu_item.formatted_price

    @ocr_menu_item.price = nil
    assert_nil @ocr_menu_item.formatted_price
  end

  test 'should return display name with price' do
    @ocr_menu_item.name = 'Bruschetta'
    @ocr_menu_item.price = 8.99
    assert_equal 'Bruschetta - $8.99', @ocr_menu_item.display_name

    @ocr_menu_item.price = nil
    assert_equal 'Bruschetta', @ocr_menu_item.display_name
  end

  test 'should return dietary information' do
    @ocr_menu_item.dietary_restrictions = %w[vegetarian vegan]
    assert_equal 'Vegetarian, Vegan', @ocr_menu_item.dietary_info

    @ocr_menu_item.dietary_restrictions = []
    assert_nil @ocr_menu_item.dietary_info
  end

  test 'should return allergen information' do
    @ocr_menu_item.allergens = %w[gluten dairy]
    assert_equal 'Contains: Gluten, Dairy', @ocr_menu_item.allergen_info

    @ocr_menu_item.allergens = []
    assert_nil @ocr_menu_item.allergen_info
  end

  test 'should create from data' do
    item_data = {
      name: 'Calamari',
      description: 'Fried squid with marinara sauce',
      price: 12.99,
      allergens: %w[shellfish gluten],
      dietary_restrictions: [],
    }

    position = 1

    assert_difference 'OcrMenuItem.count', 1 do
      item = OcrMenuItem.create_from_data(@ocr_menu_section, item_data, position)

      assert_equal @ocr_menu_section, item.ocr_menu_section
      assert_equal 'Calamari', item.name
      assert_equal 'Fried squid with marinara sauce', item.description
      assert_equal 12.99, item.price.to_f
      assert_equal %w[shellfish gluten], item.allergens
      assert_empty item.dietary_restrictions
      assert_equal position, item.position
    end
  end

  test 'should update from params' do
    @ocr_menu_item.save!

    params = {
      name: 'Updated Bruschetta',
      description: 'Updated description',
      price: '9.99',
      allergens: %w[gluten garlic],
      dietary_restrictions: %w[vegetarian vegan],
    }

    @ocr_menu_item.update_from_params(params)

    assert_equal 'Updated Bruschetta', @ocr_menu_item.name
    assert_equal 'Updated description', @ocr_menu_item.description
    assert_equal 9.99, @ocr_menu_item.price.to_f
    assert_equal %w[gluten garlic], @ocr_menu_item.allergens
    assert_equal %w[vegetarian vegan], @ocr_menu_item.dietary_restrictions
  end
end
