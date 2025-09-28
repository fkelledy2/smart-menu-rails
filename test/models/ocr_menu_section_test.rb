require 'test_helper'

class OcrMenuSectionTest < ActiveSupport::TestCase
  include OcrMenuImportsTestHelper

  setup do
    @restaurant = restaurants(:one)
    @ocr_menu_import = OcrMenuImport.create!(
      restaurant: @restaurant,
      name: 'Test Menu Import',
      status: :completed,
    )

    @ocr_menu_section = OcrMenuSection.new(
      ocr_menu_import: @ocr_menu_import,
      name: 'Starters',
      description: 'Delicious starters to begin your meal',
      position: 1,
    )
  end

  test 'should be valid with valid attributes' do
    assert @ocr_menu_section.valid?
  end

  test 'should require an ocr_menu_import' do
    @ocr_menu_section.ocr_menu_import = nil
    assert_not @ocr_menu_section.valid?
    assert_includes @ocr_menu_section.errors[:ocr_menu_import], 'must exist'
  end

  test 'should require a name' do
    @ocr_menu_section.name = nil
    assert_not @ocr_menu_section.valid?
    assert_includes @ocr_menu_section.errors[:name], "can't be blank"
  end

  test 'should have many items' do
    assert_respond_to @ocr_menu_section, :ocr_menu_items
  end

  test 'should have a default position' do
    section = OcrMenuSection.new(
      ocr_menu_import: @ocr_menu_import,
      name: 'Mains',
    )
    assert section.valid?
    assert_not_nil section.position
  end

  test 'should be orderable by position' do
    # Create sections in reverse order
    OcrMenuSection.create!(
      ocr_menu_import: @ocr_menu_import,
      name: 'Desserts',
      position: 3,
    )

    OcrMenuSection.create!(
      ocr_menu_import: @ocr_menu_import,
      name: 'Mains',
      position: 2,
    )

    OcrMenuSection.create!(
      ocr_menu_import: @ocr_menu_import,
      name: 'Starters',
      position: 1,
    )

    # Should be ordered by position
    assert_equal %w[Starters Mains Desserts],
                 @ocr_menu_import.ocr_menu_sections.ordered.pluck(:name)
  end

  test 'should create items from data' do
    section_data = {
      name: 'Starters',
      description: 'Delicious starters to begin your meal',
      items: [
        {
          name: 'Bruschetta',
          description: 'Toasted bread with tomatoes, garlic and basil',
          price: 8.99,
          allergens: ['gluten'],
          dietary_restrictions: ['vegetarian'],
        },
        {
          name: 'Calamari',
          description: 'Fried squid with marinara sauce',
          price: 12.99,
          allergens: %w[shellfish gluten],
          dietary_restrictions: [],
        },
      ],
    }

    assert_difference 'OcrMenuItem.count', 2 do
      @ocr_menu_section.create_items_from_data(section_data)
    end

    # Reload to get associations
    @ocr_menu_section.reload

    # Check items were created correctly
    assert_equal 2, @ocr_menu_section.ocr_menu_items.count
    assert_equal %w[Bruschetta Calamari],
                 @ocr_menu_section.ocr_menu_items.pluck(:name).sort

    # Check item details
    bruschetta = @ocr_menu_section.ocr_menu_items.find_by(name: 'Bruschetta')
    assert_equal 'Toasted bread with tomatoes, garlic and basil', bruschetta.description
    assert_equal 8.99, bruschetta.price.to_f
    assert_includes bruschetta.allergens, 'gluten'
    assert_includes bruschetta.dietary_restrictions, 'vegetarian'

    # Check positions were set correctly
    assert_equal [1, 2], @ocr_menu_section.ocr_menu_items.pluck(:position).sort
  end

  test 'should mark section and items as confirmed' do
    @ocr_menu_section.save!

    # Create some items
    item1 = OcrMenuItem.create!(
      ocr_menu_section: @ocr_menu_section,
      name: 'Bruschetta',
      description: 'Toasted bread with tomatoes, garlic and basil',
      price: 8.99,
      position: 1,
    )

    item2 = OcrMenuItem.create!(
      ocr_menu_section: @ocr_menu_section,
      name: 'Calamari',
      description: 'Fried squid with marinara sauce',
      price: 12.99,
      position: 2,
    )

    # Confirm the section
    @ocr_menu_section.confirm!

    # Reload to get updated attributes
    @ocr_menu_section.reload
    item1.reload
    item2.reload

    # Check section was confirmed
    assert @ocr_menu_section.confirmed?

    # Check items were confirmed
    assert item1.confirmed?
    assert item2.confirmed?
  end
end
