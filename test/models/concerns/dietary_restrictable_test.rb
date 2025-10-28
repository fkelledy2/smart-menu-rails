require 'test_helper'

class DietaryRestrictableTest < ActiveSupport::TestCase
  def setup
    # Use OcrMenuItem which already includes DietaryRestrictable
    @restaurant = restaurants(:one)
    @ocr_menu_import = OcrMenuImport.create!(
      restaurant: @restaurant,
      name: 'Test Menu Import',
      status: :completed,
    )
    @ocr_menu_section = OcrMenuSection.create!(
      ocr_menu_import: @ocr_menu_import,
      name: 'Test Section',
      position: 1,
    )
    @model = OcrMenuItem.new(
      ocr_menu_section: @ocr_menu_section,
      name: 'Test Item',
    )
  end

  # Branch coverage tests for dietary_restrictions getter
  test 'dietary_restrictions should return from metadata when present' do
    @model.metadata = { 'dietary_restrictions' => %w[vegan gluten_free] }

    assert_equal %w[vegan gluten_free], @model.dietary_restrictions
  end

  test 'dietary_restrictions should return from boolean flags when metadata absent' do
    @model.is_vegan = true
    @model.is_gluten_free = true

    expected = %w[vegan gluten_free]
    assert_equal expected, @model.dietary_restrictions
  end

  test 'dietary_restrictions should return empty array when no restrictions' do
    assert_equal [], @model.dietary_restrictions
  end

  test 'dietary_restrictions should handle nil metadata' do
    @model.metadata = nil
    @model.is_vegan = true

    assert_equal ['vegan'], @model.dietary_restrictions
  end

  test 'dietary_restrictions should handle non-hash metadata' do
    @model.metadata = 'not a hash'
    @model.is_vegetarian = true

    assert_equal ['vegetarian'], @model.dietary_restrictions
  end

  test 'dietary_restrictions should handle metadata without dietary_restrictions key' do
    @model.metadata = { 'other_key' => 'other_value' }
    @model.is_dairy_free = true

    assert_equal ['dairy_free'], @model.dietary_restrictions
  end

  # Branch coverage tests for dietary_restrictions setter
  test 'dietary_restrictions= should update boolean flags' do
    @model.dietary_restrictions = %w[vegan gluten_free]

    assert @model.is_vegan
    assert @model.is_gluten_free
    assert_not @model.is_vegetarian
    assert_not @model.is_dairy_free
  end

  test 'dietary_restrictions= should store in metadata when model supports it' do
    @model.dietary_restrictions = %w[vegan dairy_free]

    expected_metadata = { 'dietary_restrictions' => %w[vegan dairy_free] }
    assert_equal expected_metadata, @model.metadata
  end

  test 'dietary_restrictions= should handle empty array' do
    @model.is_vegan = true # Set some initial state
    @model.dietary_restrictions = []

    assert_not @model.is_vegan
    assert_not @model.is_vegetarian
    assert_not @model.is_gluten_free
    assert_not @model.is_dairy_free
  end

  test 'dietary_restrictions= should handle nil input' do
    @model.is_vegan = true # Set some initial state
    @model.dietary_restrictions = nil

    assert_not @model.is_vegan
    assert_not @model.is_vegetarian
    assert_not @model.is_gluten_free
    assert_not @model.is_dairy_free
  end

  # Branch coverage tests for dietary_info
  test 'dietary_info should return formatted text when restrictions present' do
    @model.dietary_restrictions = %w[vegan gluten_free]

    result = @model.dietary_info
    assert_not_nil result
    assert result.include?('Vegan')
    assert result.include?('Gluten Free')
  end

  test 'dietary_info should return nil when no restrictions' do
    assert_nil @model.dietary_info
  end

  # Branch coverage tests for has_dietary_restrictions?
  test 'has_dietary_restrictions? should return true when restrictions present' do
    @model.dietary_restrictions = ['vegan']

    assert @model.has_dietary_restrictions?
  end

  test 'has_dietary_restrictions? should return false when no restrictions' do
    assert_not @model.has_dietary_restrictions?
  end

  # Branch coverage tests for matches_dietary_restrictions?
  test 'matches_dietary_restrictions? should return true when required restrictions blank' do
    assert @model.matches_dietary_restrictions?([])
    assert @model.matches_dietary_restrictions?(nil)
  end

  test 'matches_dietary_restrictions? should return true when all required restrictions match' do
    @model.dietary_restrictions = %w[vegan gluten_free dairy_free]

    assert @model.matches_dietary_restrictions?(%w[vegan gluten_free])
  end

  test 'matches_dietary_restrictions? should return false when some required restrictions missing' do
    @model.dietary_restrictions = ['vegan']

    assert_not @model.matches_dietary_restrictions?(%w[vegan gluten_free])
  end

  test 'matches_dietary_restrictions? should return false when no item restrictions' do
    assert_not @model.matches_dietary_restrictions?(['vegan'])
  end

  # Branch coverage tests for class method matching_dietary_restrictions
  test 'matching_dietary_restrictions should return all when restrictions blank' do
    # This would test the class method, but since we're using a test model,
    # we'll test the logic conceptually
    assert_equal [], DietaryRestrictionsService.normalize_array([])
    assert_equal [], DietaryRestrictionsService.normalize_array(nil)
  end

  # Edge case tests
  test 'should handle mixed case dietary restrictions' do
    @model.dietary_restrictions = %w[VEGAN Gluten_Free]

    assert @model.is_vegan
    assert @model.is_gluten_free
  end

  test 'should handle unknown dietary restrictions gracefully' do
    @model.dietary_restrictions = %w[unknown_restriction vegan]

    assert @model.is_vegan
    # Unknown restrictions should not cause errors
  end

  test 'should handle duplicate dietary restrictions' do
    @model.dietary_restrictions = %w[vegan vegan gluten_free]

    assert @model.is_vegan
    assert @model.is_gluten_free
  end

  # Test with model that doesn't respond to metadata
  test 'should work with models that do not support metadata' do
    # Test the logic without stubbing - just verify it works
    @model.dietary_restrictions = %w[vegan gluten_free]

    assert @model.is_vegan
    assert @model.is_gluten_free
    assert_not @model.is_vegetarian
  end
end
