require 'test_helper'

class GooglePlaces::AddressResolverTest < ActiveSupport::TestCase
  # ── extract_fields (pure logic, no API) ──

  test 'extract_fields returns postcode and country_code from address_components' do
    components = [
      { 'types' => ['street_number'], 'long_name' => '42' },
      { 'types' => ['route'], 'long_name' => 'Grafton Street' },
      { 'types' => ['locality'], 'long_name' => 'Dublin' },
      { 'types' => ['administrative_area_level_1'], 'short_name' => 'L' },
      { 'types' => ['postal_code'], 'long_name' => 'D02 XY45' },
      { 'types' => ['country'], 'short_name' => 'IE' },
    ]

    fields = GooglePlaces::AddressResolver.extract_fields(components)

    assert_equal 'D02 XY45', fields[:postcode]
    assert_equal 'IE', fields[:country_code]
    assert_equal 'Dublin', fields[:city]
    assert_equal 'L', fields[:state]
    assert_equal '42 Grafton Street', fields[:address1]
  end

  test 'extract_fields handles missing components gracefully' do
    components = [
      { 'types' => ['country'], 'short_name' => 'US' },
    ]

    fields = GooglePlaces::AddressResolver.extract_fields(components)

    assert_equal 'US', fields[:country_code]
    assert_nil fields[:postcode]
    assert_nil fields[:city]
    assert_nil fields[:state]
    assert_nil fields[:address1]
  end

  test 'extract_fields returns empty hash for empty components' do
    fields = GooglePlaces::AddressResolver.extract_fields([])
    assert_equal({}, fields)
  end

  test 'extract_fields uses postal_town when locality is missing' do
    components = [
      { 'types' => ['postal_town'], 'long_name' => 'London' },
      { 'types' => ['postal_code'], 'long_name' => 'SW1A 1AA' },
      { 'types' => ['country'], 'short_name' => 'GB' },
    ]

    fields = GooglePlaces::AddressResolver.extract_fields(components)

    assert_equal 'London', fields[:city]
    assert_equal 'SW1A 1AA', fields[:postcode]
    assert_equal 'GB', fields[:country_code]
  end

  test 'extract_fields uppercases country_code' do
    components = [
      { 'types' => ['country'], 'short_name' => 'ie' },
    ]

    fields = GooglePlaces::AddressResolver.extract_fields(components)
    assert_equal 'IE', fields[:country_code]
  end
end
