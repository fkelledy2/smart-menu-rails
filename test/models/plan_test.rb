require 'test_helper'

class PlanTest < ActiveSupport::TestCase
  def setup
    @plan = plans(:one)
  end

  # Association tests
  test 'should have many users' do
    assert_respond_to @plan, :users
  end

  test 'should have many userplans' do
    assert_respond_to @plan, :userplans
  end

  test 'should have many features through features_plans' do
    assert_respond_to @plan, :features
  end

  # Branch coverage tests for getLanguages method
  test 'getLanguages should return "Unlimited" when languages is -1' do
    @plan.update!(languages: -1)
    assert_equal 'Unlimited', @plan.getLanguages
  end

  test 'getLanguages should return numeric value when languages is not -1' do
    @plan.update!(languages: 5)
    assert_equal 5, @plan.getLanguages
  end

  test 'getLanguages should return 0 when languages is 0' do
    @plan.update!(languages: 0)
    assert_equal 0, @plan.getLanguages
  end

  # Branch coverage tests for getLocations method
  test 'getLocations should return "Unlimited" when locations is -1' do
    @plan.update!(locations: -1)
    assert_equal 'Unlimited', @plan.getLocations
  end

  test 'getLocations should return numeric value when locations is not -1' do
    @plan.update!(locations: 3)
    assert_equal 3, @plan.getLocations
  end

  test 'getLocations should return 0 when locations is 0' do
    @plan.update!(locations: 0)
    assert_equal 0, @plan.getLocations
  end

  # Branch coverage tests for getItemsPerMenu method
  test 'getItemsPerMenu should return "Unlimited" when itemspermenu is -1' do
    @plan.update!(itemspermenu: -1)
    assert_equal 'Unlimited', @plan.getItemsPerMenu
  end

  test 'getItemsPerMenu should return numeric value when itemspermenu is not -1' do
    @plan.update!(itemspermenu: 50)
    assert_equal 50, @plan.getItemsPerMenu
  end

  test 'getItemsPerMenu should return 0 when itemspermenu is 0' do
    @plan.update!(itemspermenu: 0)
    assert_equal 0, @plan.getItemsPerMenu
  end

  # Branch coverage tests for getMenusPerLocation method
  test 'getMenusPerLocation should return "Unlimited" when menusperlocation is -1' do
    @plan.update!(menusperlocation: -1)
    assert_equal 'Unlimited', @plan.getMenusPerLocation
  end

  test 'getMenusPerLocation should return numeric value when menusperlocation is not -1' do
    @plan.update!(menusperlocation: 10)
    assert_equal 10, @plan.getMenusPerLocation
  end

  test 'getMenusPerLocation should return 0 when menusperlocation is 0' do
    @plan.update!(menusperlocation: 0)
    assert_equal 0, @plan.getMenusPerLocation
  end

  # Edge case tests
  test 'should handle negative values other than -1' do
    @plan.update!(languages: -5)
    assert_equal(-5, @plan.getLanguages)
  end

  test 'should handle large positive values' do
    @plan.update!(locations: 999_999)
    assert_equal 999_999, @plan.getLocations
  end

  # Validation tests
  test 'should be valid with valid attributes' do
    plan = Plan.new(
      key: 'plan.test.key',
      pricePerMonth: 29.99,
      languages: 5,
      locations: 3,
      itemspermenu: 150,
      menusperlocation: 10,
    )
    assert plan.valid?
  end

  # Branch coverage tests for name method
  test 'name should return "Starter" for starter plan key' do
    @plan.update!(key: 'plan.starter.key')
    assert_equal 'Starter', @plan.name
  end

  test 'name should return "Professional" for pro plan key' do
    @plan.update!(key: 'plan.pro.key')
    assert_equal 'Professional', @plan.name
  end

  test 'name should return "Business" for business plan key' do
    @plan.update!(key: 'plan.business.key')
    assert_equal 'Business', @plan.name
  end

  test 'name should return "Enterprise" for enterprise plan key' do
    @plan.update!(key: 'plan.enterprise.key')
    assert_equal 'Enterprise', @plan.name
  end

  test 'name should return humanized key for unknown plan key' do
    @plan.update!(key: 'plan.custom.key')
    assert_equal 'Plan.custom.key', @plan.name
  end

  test 'name should handle nil key' do
    @plan.update!(key: nil)
    assert_nil @plan.name
  end

  test 'display_order returns plans in starter, professional, business, enterprise order' do
    # Clean up associations first to avoid foreign key constraints
    ActiveRecord::Base.connection.execute('DELETE FROM features_plans')
    ActiveRecord::Base.connection.execute('DELETE FROM userplans')
    Plan.delete_all

    enterprise = Plan.create!(key: 'plan.enterprise.key', status: :active, action: :call)
    business = Plan.create!(
      key: 'plan.business.key',
      status: :active,
      action: :register,
      stripe_price_id_month: 'price_test_business_month',
    )
    pro = Plan.create!(
      key: 'plan.pro.key',
      status: :active,
      action: :register,
      stripe_price_id_month: 'price_test_pro_month',
    )
    starter = Plan.create!(
      key: 'plan.starter.key',
      status: :active,
      action: :register,
      stripe_price_id_month: 'price_test_starter_month',
    )

    assert_equal [starter.id, pro.id, business.id, enterprise.id], Plan.display_order.pluck(:id)
  end
end
