require 'test_helper'

class TaxTest < ActiveSupport::TestCase
  def setup
    @tax = taxes(:one)
    @restaurant = restaurants(:one)
  end

  # === VALIDATION TESTS ===

  test 'should be valid with valid attributes' do
    assert @tax.valid?
  end

  test 'should require name' do
    @tax.name = nil
    assert_not @tax.valid?
    assert_includes @tax.errors[:name], "can't be blank"
  end

  test 'should require taxpercentage' do
    @tax.taxpercentage = nil
    assert_not @tax.valid?
    assert_includes @tax.errors[:taxpercentage], "can't be blank"
  end

  test 'should require numeric taxpercentage' do
    @tax.taxpercentage = 'not_a_number'
    assert_not @tax.valid?
    assert_includes @tax.errors[:taxpercentage], 'is not a number'
  end

  test 'should accept float taxpercentage' do
    @tax.taxpercentage = 8.25
    assert @tax.valid?
  end

  test 'should accept integer taxpercentage' do
    @tax.taxpercentage = 10
    assert @tax.valid?
  end

  # === ASSOCIATION TESTS ===

  test 'should belong to restaurant' do
    assert_respond_to @tax, :restaurant
    assert_instance_of Restaurant, @tax.restaurant
  end

  # === ENUM TESTS ===

  test 'should have correct taxtype enum values' do
    assert_equal 0, Tax.taxtypes[:local]
    assert_equal 1, Tax.taxtypes[:state]
    assert_equal 2, Tax.taxtypes[:federal]
    assert_equal 3, Tax.taxtypes[:service]
  end

  test 'should have correct status enum values' do
    assert_equal 0, Tax.statuses[:inactive]
    assert_equal 1, Tax.statuses[:active]
    assert_equal 2, Tax.statuses[:archived]
  end

  test 'should allow taxtype changes' do
    @tax.local!
    assert @tax.local?

    @tax.state!
    assert @tax.state?

    @tax.federal!
    assert @tax.federal?

    @tax.service!
    assert @tax.service?
  end

  test 'should allow status changes' do
    @tax.active!
    assert @tax.active?

    @tax.archived!
    assert @tax.archived?

    @tax.inactive!
    assert @tax.inactive?
  end

  # === FACTORY/CREATION TESTS ===

  test 'should create tax with valid data' do
    tax = Tax.new(
      name: 'Sales Tax',
      taxpercentage: 8.25,
      taxtype: :state,
      status: :active,
      restaurant: @restaurant,
    )
    assert tax.save
    assert_equal 'Sales Tax', tax.name
    assert_equal 8.25, tax.taxpercentage
    assert tax.state?
    assert tax.active?
  end

  test 'should create service tax' do
    tax = Tax.new(
      name: 'Service Charge',
      taxpercentage: 15.0,
      taxtype: :service,
      status: :active,
      restaurant: @restaurant,
    )
    assert tax.save
    assert tax.service?
    assert_equal 15.0, tax.taxpercentage
  end

  # === IDENTITY CACHE TESTS ===

  test 'should have identity cache configured' do
    assert Tax.respond_to?(:cache_index)
  end
end
