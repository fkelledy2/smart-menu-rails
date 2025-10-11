require 'test_helper'
require 'ostruct'

class DietaryRestrictionsServiceTest < ActiveSupport::TestCase
  # Constants and structure tests
  test 'should define supported restrictions' do
    expected_restrictions = %w[vegetarian vegan gluten_free dairy_free]
    assert_equal expected_restrictions, DietaryRestrictionsService::SUPPORTED_RESTRICTIONS
  end

  test 'should define restriction to boolean mapping' do
    expected_mapping = {
      'vegetarian' => :is_vegetarian,
      'vegan' => :is_vegan,
      'gluten_free' => :is_gluten_free,
      'dairy_free' => :is_dairy_free,
    }
    assert_equal expected_mapping, DietaryRestrictionsService::RESTRICTION_TO_BOOLEAN
  end

  test 'should define boolean to restriction mapping' do
    expected_mapping = {
      'is_vegetarian' => 'vegetarian',
      'is_vegan' => 'vegan',
      'is_gluten_free' => 'gluten_free',
      'is_dairy_free' => 'dairy_free',
    }
    assert_equal expected_mapping, DietaryRestrictionsService::BOOLEAN_TO_RESTRICTION
  end

  test 'should have consistent mappings' do
    # Verify that the mappings are inverses of each other
    DietaryRestrictionsService::RESTRICTION_TO_BOOLEAN.each do |restriction, boolean_attr|
      assert_equal restriction, DietaryRestrictionsService::BOOLEAN_TO_RESTRICTION[boolean_attr.to_s]
    end
  end

  # Normalization tests
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

  test 'normalize_array should handle symbols' do
    assert_equal ['vegetarian'], DietaryRestrictionsService.normalize_array([:vegetarian])
    assert_equal %w[vegetarian vegan], DietaryRestrictionsService.normalize_array(%i[vegetarian vegan])
  end

  test 'normalize_array should remove duplicates' do
    assert_equal ['vegetarian'],
                 DietaryRestrictionsService.normalize_array(['vegetarian', 'VEGETARIAN', ' vegetarian '])
  end

  test 'normalize_array should handle empty strings and nils in array' do
    input = ['vegetarian', '', nil, 'vegan', '   ']
    assert_equal %w[vegetarian vegan], DietaryRestrictionsService.normalize_array(input)
  end

  test 'normalize_array should handle numeric inputs gracefully' do
    assert_equal [], DietaryRestrictionsService.normalize_array([1, 2, 3])
  end

  test 'normalize_array should preserve order while removing duplicates' do
    input = %w[vegan vegetarian gluten_free vegetarian dairy_free]
    expected = %w[vegan vegetarian gluten_free dairy_free]
    assert_equal expected, DietaryRestrictionsService.normalize_array(input)
  end

  # Array to boolean flags tests
  test 'array_to_boolean_flags converts correctly' do
    flags = DietaryRestrictionsService.array_to_boolean_flags(%w[vegetarian gluten_free])

    assert_equal true, flags[:is_vegetarian]
    assert_equal false, flags[:is_vegan]
    assert_equal true, flags[:is_gluten_free]
    assert_equal false, flags[:is_dairy_free]
  end

  test 'array_to_boolean_flags should handle empty array' do
    flags = DietaryRestrictionsService.array_to_boolean_flags([])

    assert_equal false, flags[:is_vegetarian]
    assert_equal false, flags[:is_vegan]
    assert_equal false, flags[:is_gluten_free]
    assert_equal false, flags[:is_dairy_free]
  end

  test 'array_to_boolean_flags should handle nil input' do
    flags = DietaryRestrictionsService.array_to_boolean_flags(nil)

    assert_equal false, flags[:is_vegetarian]
    assert_equal false, flags[:is_vegan]
    assert_equal false, flags[:is_gluten_free]
    assert_equal false, flags[:is_dairy_free]
  end

  test 'array_to_boolean_flags should normalize input' do
    flags = DietaryRestrictionsService.array_to_boolean_flags([' VEGETARIAN ', 'invalid_restriction'])

    assert_equal true, flags[:is_vegetarian]
    assert_equal false, flags[:is_vegan]
    assert_equal false, flags[:is_gluten_free]
    assert_equal false, flags[:is_dairy_free]
  end

  test 'array_to_boolean_flags should handle all supported restrictions' do
    all_restrictions = DietaryRestrictionsService::SUPPORTED_RESTRICTIONS
    flags = DietaryRestrictionsService.array_to_boolean_flags(all_restrictions)

    assert_equal true, flags[:is_vegetarian]
    assert_equal true, flags[:is_vegan]
    assert_equal true, flags[:is_gluten_free]
    assert_equal true, flags[:is_dairy_free]
  end

  # Boolean flags to array tests
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

  test 'boolean_flags_to_array should handle nil record' do
    restrictions = DietaryRestrictionsService.boolean_flags_to_array(nil)
    assert_equal [], restrictions
  end

  test 'boolean_flags_to_array should handle record with no restrictions' do
    record = OpenStruct.new(
      is_vegetarian: false,
      is_vegan: false,
      is_gluten_free: false,
      is_dairy_free: false,
    )

    restrictions = DietaryRestrictionsService.boolean_flags_to_array(record)
    assert_equal [], restrictions
  end

  test 'boolean_flags_to_array should handle record with all restrictions' do
    record = OpenStruct.new(
      is_vegetarian: true,
      is_vegan: true,
      is_gluten_free: true,
      is_dairy_free: true,
    )

    restrictions = DietaryRestrictionsService.boolean_flags_to_array(record)
    assert_equal %w[dairy_free gluten_free vegan vegetarian], restrictions.sort
  end

  test 'boolean_flags_to_array should handle record missing some attributes' do
    record = OpenStruct.new(
      is_vegetarian: true,
      is_vegan: false,
      # Missing is_gluten_free and is_dairy_free
    )

    restrictions = DietaryRestrictionsService.boolean_flags_to_array(record)
    assert_equal ['vegetarian'], restrictions
  end

  test 'boolean_flags_to_array should handle record with nil boolean values' do
    record = OpenStruct.new(
      is_vegetarian: true,
      is_vegan: nil,
      is_gluten_free: false,
      is_dairy_free: nil,
    )

    restrictions = DietaryRestrictionsService.boolean_flags_to_array(record)
    assert_equal ['vegetarian'], restrictions
  end

  # Display text tests
  test 'display_text formats correctly' do
    assert_equal 'Vegetarian, Gluten Free', DietaryRestrictionsService.display_text(%w[vegetarian gluten_free])
    assert_equal 'Dairy Free', DietaryRestrictionsService.display_text(['dairy_free'])
    assert_nil DietaryRestrictionsService.display_text([])
    assert_nil DietaryRestrictionsService.display_text(nil)
  end

  test 'display_text should handle single restriction' do
    assert_equal 'Vegan', DietaryRestrictionsService.display_text(['vegan'])
  end

  test 'display_text should handle all restrictions' do
    all_restrictions = DietaryRestrictionsService::SUPPORTED_RESTRICTIONS
    result = DietaryRestrictionsService.display_text(all_restrictions)
    assert_equal 'Vegetarian, Vegan, Gluten Free, Dairy Free', result
  end

  test 'display_text should normalize input before formatting' do
    result = DietaryRestrictionsService.display_text([' VEGETARIAN ', 'invalid', 'gluten_FREE'])
    assert_equal 'Vegetarian, Gluten Free', result
  end

  test 'display_text should handle mixed case underscores correctly' do
    result = DietaryRestrictionsService.display_text(%w[gluten_free dairy_free])
    assert_equal 'Gluten Free, Dairy Free', result
  end

  # Has restrictions tests
  test 'has_restrictions? detects restrictions' do
    record_with_restrictions = OpenStruct.new(is_vegetarian: true, is_vegan: false, is_gluten_free: false,
                                              is_dairy_free: false,)
    record_without_restrictions = OpenStruct.new(is_vegetarian: false, is_vegan: false, is_gluten_free: false,
                                                 is_dairy_free: false,)

    assert DietaryRestrictionsService.has_restrictions?(record_with_restrictions)
    assert_not DietaryRestrictionsService.has_restrictions?(record_without_restrictions)
  end

  test 'has_restrictions? should handle nil record' do
    assert_not DietaryRestrictionsService.has_restrictions?(nil)
  end

  test 'has_restrictions? should handle record with multiple restrictions' do
    record = OpenStruct.new(
      is_vegetarian: true,
      is_vegan: true,
      is_gluten_free: false,
      is_dairy_free: false,
    )

    assert DietaryRestrictionsService.has_restrictions?(record)
  end

  test 'has_restrictions? should handle record missing attributes' do
    record = OpenStruct.new(is_vegetarian: true)
    assert DietaryRestrictionsService.has_restrictions?(record)
  end

  # Update boolean flags tests
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

  test 'update_boolean_flags should handle record supporting all attributes' do
    record = OpenStruct.new
    def record.respond_to?(method)
      %w[is_vegetarian= is_vegan= is_gluten_free= is_dairy_free=].include?(method.to_s)
    end

    flags = DietaryRestrictionsService.update_boolean_flags(record, %w[vegetarian gluten_free])

    assert_equal true, flags[:is_vegetarian]
    assert_equal false, flags[:is_vegan]
    assert_equal true, flags[:is_gluten_free]
    assert_equal false, flags[:is_dairy_free]
  end

  test 'update_boolean_flags should handle record supporting no attributes' do
    record = OpenStruct.new
    def record.respond_to?(_method)
      false
    end

    flags = DietaryRestrictionsService.update_boolean_flags(record, %w[vegetarian vegan])
    assert_equal({}, flags)
  end

  test 'update_boolean_flags should handle empty restrictions array' do
    record = OpenStruct.new
    def record.respond_to?(method)
      %w[is_vegetarian= is_vegan=].include?(method.to_s)
    end

    flags = DietaryRestrictionsService.update_boolean_flags(record, [])

    assert_equal false, flags[:is_vegetarian]
    assert_equal false, flags[:is_vegan]
  end

  # Validation tests
  test 'validate_restrictions returns errors for unsupported restrictions' do
    errors = DietaryRestrictionsService.validate_restrictions(%w[vegetarian invalid vegan])
    assert_equal 1, errors.size
    assert_includes errors.first, 'invalid'
  end

  test 'validate_restrictions should handle empty array' do
    errors = DietaryRestrictionsService.validate_restrictions([])
    assert_equal [], errors
  end

  test 'validate_restrictions should handle nil input' do
    errors = DietaryRestrictionsService.validate_restrictions(nil)
    assert_equal [], errors
  end

  test 'validate_restrictions should handle all valid restrictions' do
    errors = DietaryRestrictionsService.validate_restrictions(DietaryRestrictionsService::SUPPORTED_RESTRICTIONS)
    assert_equal [], errors
  end

  test 'validate_restrictions should handle multiple invalid restrictions' do
    errors = DietaryRestrictionsService.validate_restrictions(%w[invalid1 vegetarian invalid2 vegan invalid3])
    assert_equal 3, errors.size
    assert_includes errors.join, 'invalid1'
    assert_includes errors.join, 'invalid2'
    assert_includes errors.join, 'invalid3'
  end

  test 'validate_restrictions should handle mixed case and whitespace' do
    errors = DietaryRestrictionsService.validate_restrictions([' VEGETARIAN ', 'Invalid_Restriction'])
    assert_equal 1, errors.size
    assert_includes errors.first, 'Invalid_Restriction'
  end

  test 'validate_restrictions should handle numeric and symbol inputs' do
    errors = DietaryRestrictionsService.validate_restrictions([123, :invalid_symbol, 'vegetarian'])
    assert_equal 2, errors.size
  end

  # Supported restrictions with display names tests
  test 'supported_restrictions_with_display_names returns formatted hash' do
    result = DietaryRestrictionsService.supported_restrictions_with_display_names

    assert_equal 'Vegetarian', result['vegetarian']
    assert_equal 'Gluten Free', result['gluten_free']
    assert_equal 'Dairy Free', result['dairy_free']
    assert_equal 'Vegan', result['vegan']
  end

  test 'supported_restrictions_with_display_names should include all supported restrictions' do
    result = DietaryRestrictionsService.supported_restrictions_with_display_names

    DietaryRestrictionsService::SUPPORTED_RESTRICTIONS.each do |restriction|
      assert_includes result.keys, restriction
      assert_instance_of String, result[restriction]
      assert result[restriction].length.positive?
    end
  end

  test 'supported_restrictions_with_display_names should format underscores correctly' do
    result = DietaryRestrictionsService.supported_restrictions_with_display_names

    # Check that underscores are converted to spaces and words are capitalized
    assert_equal 'Gluten Free', result['gluten_free']
    assert_equal 'Dairy Free', result['dairy_free']

    # Check that single words are capitalized
    assert_equal 'Vegetarian', result['vegetarian']
    assert_equal 'Vegan', result['vegan']
  end

  # Integration and edge case tests
  test 'should handle complete workflow from array to display text' do
    input = [' VEGETARIAN ', 'invalid', 'Gluten_Free', 'vegetarian']

    # Normalize
    normalized = DietaryRestrictionsService.normalize_array(input)
    assert_equal %w[vegetarian gluten_free], normalized

    # Convert to boolean flags
    flags = DietaryRestrictionsService.array_to_boolean_flags(normalized)
    assert_equal true, flags[:is_vegetarian]
    assert_equal true, flags[:is_gluten_free]
    assert_equal false, flags[:is_vegan]
    assert_equal false, flags[:is_dairy_free]

    # Display text
    display = DietaryRestrictionsService.display_text(normalized)
    assert_equal 'Vegetarian, Gluten Free', display
  end

  test 'should handle complete workflow from record to display text' do
    record = OpenStruct.new(
      is_vegetarian: false,
      is_vegan: true,
      is_gluten_free: false,
      is_dairy_free: true,
    )

    # Extract restrictions
    restrictions = DietaryRestrictionsService.boolean_flags_to_array(record)
    assert_equal %w[dairy_free vegan], restrictions.sort

    # Check has restrictions
    assert DietaryRestrictionsService.has_restrictions?(record)

    # Display text
    display = DietaryRestrictionsService.display_text(restrictions)
    assert_equal 'Vegan, Dairy Free', display
  end

  test 'should handle round-trip conversion' do
    original_restrictions = %w[vegetarian gluten_free]

    # Array -> Boolean flags
    flags = DietaryRestrictionsService.array_to_boolean_flags(original_restrictions)

    # Create mock record with flags
    record = OpenStruct.new(flags)

    # Boolean flags -> Array
    converted_restrictions = DietaryRestrictionsService.boolean_flags_to_array(record)

    assert_equal original_restrictions.sort, converted_restrictions.sort
  end

  test 'should handle empty state consistently' do
    # Empty array
    assert_equal [], DietaryRestrictionsService.normalize_array([])

    # Empty to boolean flags
    flags = DietaryRestrictionsService.array_to_boolean_flags([])
    assert(flags.values.all?(false))

    # Empty record
    empty_record = OpenStruct.new(flags)
    assert_equal [], DietaryRestrictionsService.boolean_flags_to_array(empty_record)
    assert_not DietaryRestrictionsService.has_restrictions?(empty_record)

    # Empty display
    assert_nil DietaryRestrictionsService.display_text([])

    # Empty validation
    assert_equal [], DietaryRestrictionsService.validate_restrictions([])
  end
end
