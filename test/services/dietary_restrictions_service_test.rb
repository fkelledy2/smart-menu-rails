require 'test_helper'
require 'ostruct'

class DietaryRestrictionsServiceTest < ActiveSupport::TestCase
  test 'normalize_array handles various input formats' do
    # Array input
    assert_equal %w[vegetarian vegan], DietaryRestrictionsService.normalize_array(%w[vegetarian vegan])

    # String input
    assert_equal ['vegetarian'], DietaryRestrictionsService.normalize_array('vegetarian')

    # Mixed case and whitespace
    assert_equal %w[vegetarian gluten_free],
                 DietaryRestrictionsService.normalize_array([' VEGETARIAN ', 'Gluten_Free'])

    # Filters unsupported restrictions
    assert_equal ['vegetarian'], DietaryRestrictionsService.normalize_array(%w[vegetarian unsupported])

    # Handles nil and empty
    assert_equal [], DietaryRestrictionsService.normalize_array(nil)
    assert_equal [], DietaryRestrictionsService.normalize_array([])
  end

  test 'array_to_boolean_flags converts correctly' do
    flags = DietaryRestrictionsService.array_to_boolean_flags(%w[vegetarian gluten_free])

    assert_equal true, flags[:is_vegetarian]
    assert_equal false, flags[:is_vegan]
    assert_equal true, flags[:is_gluten_free]
    assert_equal false, flags[:is_dairy_free]
  end

  test 'boolean_flags_to_array extracts from record' do
    # Create a mock record with boolean attributes
    record = OpenStruct.new(
      is_vegetarian: true,
      is_vegan: false,
      is_gluten_free: true,
      is_dairy_free: false,
    )

    restrictions = DietaryRestrictionsService.boolean_flags_to_array(record)
    assert_equal %w[gluten_free vegetarian], restrictions.sort
  end

  test 'display_text formats correctly' do
    assert_equal 'Vegetarian, Gluten Free', DietaryRestrictionsService.display_text(%w[vegetarian gluten_free])
    assert_equal 'Dairy Free', DietaryRestrictionsService.display_text(['dairy_free'])
    assert_nil DietaryRestrictionsService.display_text([])
    assert_nil DietaryRestrictionsService.display_text(nil)
  end

  test 'has_restrictions? detects restrictions' do
    record_with_restrictions = OpenStruct.new(is_vegetarian: true, is_vegan: false, is_gluten_free: false,
                                              is_dairy_free: false,)
    record_without_restrictions = OpenStruct.new(is_vegetarian: false, is_vegan: false, is_gluten_free: false,
                                                 is_dairy_free: false,)

    assert DietaryRestrictionsService.has_restrictions?(record_with_restrictions)
    assert_not DietaryRestrictionsService.has_restrictions?(record_without_restrictions)
  end

  test 'update_boolean_flags returns correct attributes' do
    # Mock record that supports some but not all attributes
    record = OpenStruct.new
    def record.respond_to?(method)
      %w[is_vegetarian= is_vegan= is_gluten_free=].include?(method.to_s)
    end

    flags = DietaryRestrictionsService.update_boolean_flags(record, %w[vegetarian dairy_free])

    # Should only include supported attributes
    assert_equal true, flags[:is_vegetarian]
    assert_equal false, flags[:is_vegan]
    assert_equal false, flags[:is_gluten_free]
    assert_not flags.key?(:is_dairy_free) # Not supported by mock record
  end

  test 'validate_restrictions returns errors for unsupported restrictions' do
    errors = DietaryRestrictionsService.validate_restrictions(%w[vegetarian invalid vegan])
    assert_equal 1, errors.size
    assert_includes errors.first, 'invalid'
  end

  test 'supported_restrictions_with_display_names returns formatted hash' do
    result = DietaryRestrictionsService.supported_restrictions_with_display_names

    assert_equal 'Vegetarian', result['vegetarian']
    assert_equal 'Gluten Free', result['gluten_free']
    assert_equal 'Dairy Free', result['dairy_free']
  end
end
