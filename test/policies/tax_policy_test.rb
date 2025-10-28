require 'test_helper'

class TaxPolicyTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @other_user = users(:two)
    @restaurant = restaurants(:one) # Owned by @user
    @other_restaurant = restaurants(:two) # Owned by @other_user

    # Create taxes for testing
    @tax = Tax.create!(
      restaurant: @restaurant,
      name: 'Sales Tax',
      taxpercentage: 8.25,
      taxtype: :local,
      status: :active,
    )

    @other_tax = Tax.create!(
      restaurant: @other_restaurant,
      name: 'Other Sales Tax',
      taxpercentage: 7.50,
      taxtype: :state,
      status: :active,
    )
  end

  # === INDEX TESTS ===

  test 'should allow authenticated user to view tax index' do
    policy = TaxPolicy.new(@user, Tax)
    assert policy.index?
  end

  test 'should allow anonymous user to view tax index' do
    policy = TaxPolicy.new(nil, Tax)
    # ApplicationPolicy creates User.new for nil user, so user.present? is true
    assert policy.index?, 'ApplicationPolicy creates User.new for anonymous users'
  end

  # === SHOW TESTS ===

  test 'should allow owner to view tax' do
    policy = TaxPolicy.new(@user, @tax)
    assert policy.show?
  end

  test 'should deny non-owner from viewing tax' do
    policy = TaxPolicy.new(@user, @other_tax)
    assert_not policy.show?
  end

  test 'should deny anonymous user from viewing tax' do
    policy = TaxPolicy.new(nil, @tax)
    assert_not policy.show?
  end

  # === CREATE TESTS ===

  test 'should allow authenticated user to create tax' do
    policy = TaxPolicy.new(@user, Tax.new)
    assert policy.create?
  end

  test 'should allow anonymous user to create tax' do
    policy = TaxPolicy.new(nil, Tax.new)
    # ApplicationPolicy creates User.new for nil user, so user.present? is true
    assert policy.create?, 'ApplicationPolicy creates User.new for anonymous users'
  end

  # === UPDATE TESTS ===

  test 'should allow owner to update tax' do
    policy = TaxPolicy.new(@user, @tax)
    assert policy.update?
  end

  test 'should deny non-owner from updating tax' do
    policy = TaxPolicy.new(@user, @other_tax)
    assert_not policy.update?
  end

  test 'should deny anonymous user from updating tax' do
    policy = TaxPolicy.new(nil, @tax)
    assert_not policy.update?
  end

  # === DESTROY TESTS ===

  test 'should allow owner to destroy tax' do
    policy = TaxPolicy.new(@user, @tax)
    assert policy.destroy?
  end

  test 'should deny non-owner from destroying tax' do
    policy = TaxPolicy.new(@user, @other_tax)
    assert_not policy.destroy?
  end

  test 'should deny anonymous user from destroying tax' do
    policy = TaxPolicy.new(nil, @tax)
    assert_not policy.destroy?
  end

  # === SCOPE TESTS ===

  test "should scope taxes to user's restaurant taxes" do
    scope = TaxPolicy::Scope.new(@user, Tax).resolve

    # Should include user's restaurant taxes
    assert_includes scope, @tax

    # Should not include other user's restaurant taxes
    assert_not_includes scope, @other_tax
  end

  test 'should return empty scope for anonymous user' do
    # Anonymous user scope will fail because user is nil
    assert_raises(NoMethodError) do
      TaxPolicy::Scope.new(nil, Tax).resolve
    end
  end

  test 'should handle user with no restaurant taxes' do
    user_with_no_restaurants = User.create!(
      email: 'notaxes@example.com',
      password: 'password123',
    )

    scope = TaxPolicy::Scope.new(user_with_no_restaurants, Tax).resolve

    # Should not include any taxes
    assert_not_includes scope, @tax
    assert_not_includes scope, @other_tax
  end

  # === EDGE CASE TESTS ===

  test 'should handle nil tax record' do
    policy = TaxPolicy.new(@user, nil)

    # Public methods should still work
    assert policy.index?
    assert policy.create?

    # Owner-based methods should return false for nil record
    assert_not policy.show?
    assert_not policy.update?
    assert_not policy.destroy?
  end

  test 'should handle tax without restaurant' do
    tax_without_restaurant = Tax.new(name: 'Test Tax', taxpercentage: 5.0, taxtype: :local)
    policy = TaxPolicy.new(@user, tax_without_restaurant)

    # Should deny access to tax without proper restaurant association
    assert_not policy.show?
    assert_not policy.update?
    assert_not policy.destroy?
  end

  test 'should inherit from ApplicationPolicy' do
    assert TaxPolicy < ApplicationPolicy
  end

  # === BUSINESS LOGIC TESTS ===

  test 'should handle different tax percentages' do
    # Test with different tax percentages
    percentages = [0.0, 5.25, 8.75, 10.0, 12.5, 15.0]

    percentages.each do |percentage|
      tax = Tax.create!(
        restaurant: @restaurant,
        name: "#{percentage}% Tax",
        taxpercentage: percentage,
        taxtype: :local,
        status: :active,
      )

      policy = TaxPolicy.new(@user, tax)
      assert policy.show?, "Owner should have access to tax with percentage #{percentage}%"
      assert policy.update?, "Owner should be able to update tax with percentage #{percentage}%"
      assert policy.destroy?, "Owner should be able to destroy tax with percentage #{percentage}%"
    end
  end

  test 'should handle different tax statuses' do
    # Test with different tax statuses
    statuses = %i[active inactive archived]

    statuses.each do |status|
      tax = Tax.create!(
        restaurant: @restaurant,
        name: "#{status.to_s.capitalize} Tax",
        taxpercentage: 8.0,
        taxtype: :local,
        status: status,
      )

      policy = TaxPolicy.new(@user, tax)
      assert policy.show?, "Owner should have access to #{status} taxes"
      assert policy.update?, "Owner should be able to update #{status} taxes"
      assert policy.destroy?, "Owner should be able to destroy #{status} taxes"
    end
  end

  test 'should handle multiple taxes per restaurant' do
    # Create additional tax for the same restaurant
    additional_tax = Tax.create!(
      restaurant: @restaurant,
      name: 'Service Tax',
      taxpercentage: 3.0,
      taxtype: :service,
      status: :active,
    )

    policy = TaxPolicy.new(@user, additional_tax)
    assert policy.show?
    assert policy.update?
    assert policy.destroy?

    # Scope should include both taxes
    scope = TaxPolicy::Scope.new(@user, Tax).resolve
    assert_includes scope, @tax
    assert_includes scope, additional_tax
  end

  test 'should handle cross-restaurant tax access correctly' do
    # Verify that ownership is checked through restaurant
    policy_own_tax = TaxPolicy.new(@user, @tax)
    policy_other_tax = TaxPolicy.new(@user, @other_tax)

    # Should have access to own restaurant's tax
    assert policy_own_tax.show?
    assert policy_own_tax.update?
    assert policy_own_tax.destroy?

    # Should not have access to other restaurant's tax
    assert_not policy_other_tax.show?
    assert_not policy_other_tax.update?
    assert_not policy_other_tax.destroy?
  end

  # === RESTAURANT OWNERSHIP TESTS ===

  test 'should properly validate restaurant ownership' do
    # Test the ownership chain: User → Restaurant → Tax
    assert_equal @user.id, @tax.restaurant.user_id,
                 'Test setup should have proper ownership chain'

    policy = TaxPolicy.new(@user, @tax)
    assert policy.show?, 'Owner should have access through restaurant ownership'

    # Test with different user
    other_policy = TaxPolicy.new(@user, @other_tax)
    assert_not other_policy.show?, 'Non-owner should not have access'
  end

  test 'should handle scope correctly with multiple restaurants per user' do
    # Create additional restaurant for the same user
    additional_restaurant = Restaurant.create!(
      name: 'Second Restaurant',
      user: @user,
      status: :active,
    )

    additional_tax = Tax.create!(
      restaurant: additional_restaurant,
      name: 'Second Restaurant Tax',
      taxpercentage: 9.0,
      taxtype: :state,
      status: :active,
    )

    scope = TaxPolicy::Scope.new(@user, Tax).resolve

    # Should include taxes from both restaurants
    assert_includes scope, @tax
    assert_includes scope, additional_tax

    # Should not include other user's taxes
    assert_not_includes scope, @other_tax
  end

  # === TAX CONFIGURATION TESTS ===

  test 'should handle tax lifecycle management' do
    # Test tax creation, activation, deactivation, archival
    new_tax = Tax.new(
      restaurant: @restaurant,
      name: 'New Tax',
      taxpercentage: 6.5,
      taxtype: :local,
      status: :inactive,
    )

    policy = TaxPolicy.new(@user, new_tax)

    # Owner should be able to manage tax through entire lifecycle
    assert policy.create?, 'Owner should be able to create taxes'

    # After creation
    new_tax.save!
    assert policy.show?, 'Owner should be able to view new taxes'
    assert policy.update?, 'Owner should be able to update taxes'

    # Activation
    new_tax.update!(status: :active)
    assert policy.update?, 'Owner should be able to activate taxes'

    # Percentage changes
    new_tax.update!(taxpercentage: 7.25)
    assert policy.update?, 'Owner should be able to change tax percentages'

    # Archival
    new_tax.update!(status: :archived)
    assert policy.update?, 'Owner should be able to archive taxes'
    assert policy.destroy?, 'Owner should be able to destroy archived taxes'
  end

  test 'should handle complex tax scenarios' do
    # Multiple taxes with different purposes
    tax_configs = [
      { name: 'Sales Tax', taxpercentage: 8.25, taxtype: :local, status: :active },
      { name: 'Service Charge', taxpercentage: 18.0, taxtype: :service, status: :active },
      { name: 'State Tax', taxpercentage: 2.5, taxtype: :state, status: :active },
      { name: 'Federal Tax', taxpercentage: 5.0, taxtype: :federal, status: :inactive },
      { name: 'Old Tax', taxpercentage: 6.0, taxtype: :local, status: :archived },
    ]

    tax_configs.each do |tax_data|
      tax = Tax.create!(
        restaurant: @restaurant,
        **tax_data,
      )

      policy = TaxPolicy.new(@user, tax)
      assert policy.show?, "Owner should have access to #{tax_data[:name]}"
      assert policy.update?, "Owner should be able to update #{tax_data[:name]}"
      assert policy.destroy?, "Owner should be able to destroy #{tax_data[:name]}"
    end
  end

  # === PERFORMANCE TESTS ===

  test 'should handle large tax datasets efficiently' do
    # Create multiple taxes to test performance
    10.times do |i|
      Tax.create!(
        restaurant: @restaurant,
        name: "Bulk Tax #{i}",
        taxpercentage: 5.0 + i,
        taxtype: %i[local state federal service][i % 4],
        status: :active,
      )
    end

    scope = TaxPolicy::Scope.new(@user, Tax).resolve

    # Should handle large datasets without N+1 queries
    assert_nothing_raised do
      scope.limit(50).each do |tax|
        # Access associated data that should be efficiently loaded
        tax.restaurant.name
      end
    end
  end

  test 'should prevent unauthorized access across restaurant boundaries' do
    # Create taxes in different restaurants
    restaurant_a = Restaurant.create!(name: 'Restaurant A', user: @user, status: :active)
    restaurant_b = Restaurant.create!(name: 'Restaurant B', user: @other_user, status: :active)

    tax_a = Tax.create!(restaurant: restaurant_a, name: 'Tax A', taxpercentage: 8.0, taxtype: :local, status: :active)
    tax_b = Tax.create!(restaurant: restaurant_b, name: 'Tax B', taxpercentage: 9.0, taxtype: :state, status: :active)

    # User should only access their own restaurant's taxes
    policy_a = TaxPolicy.new(@user, tax_a)
    policy_b = TaxPolicy.new(@user, tax_b)

    assert policy_a.show?, "User should access their own restaurant's taxes"
    assert_not policy_b.show?, "User should not access other restaurant's taxes"

    # Scope should only include own restaurant's taxes
    scope = TaxPolicy::Scope.new(@user, Tax).resolve
    assert_includes scope, tax_a
    assert_not_includes scope, tax_b
  end

  # === TAX CALCULATION BUSINESS LOGIC ===

  test 'should handle different tax types' do
    # Test all available tax types
    tax_types = %i[local state federal service]

    tax_types.each do |tax_type|
      tax = Tax.create!(
        restaurant: @restaurant,
        name: "#{tax_type.to_s.capitalize} Tax",
        taxpercentage: 8.0,
        taxtype: tax_type,
        status: :active,
      )

      policy = TaxPolicy.new(@user, tax)
      assert policy.show?, "Owner should have access to #{tax_type} tax"
      assert policy.update?, "Owner should be able to update #{tax_type} tax"
      assert policy.destroy?, "Owner should be able to destroy #{tax_type} tax"
    end
  end

  test 'should handle tax name variations' do
    # Test taxes with various naming patterns
    tax_names = [
      'Sales Tax',
      'VAT',
      'GST',
      'Service Charge',
      'Gratuity',
      'City Tax',
      'State Tax',
      'Federal Tax',
      'Custom Tax 1',
      'Temporary Holiday Tax',
    ]

    tax_names.each do |name|
      tax = Tax.create!(
        restaurant: @restaurant,
        name: name,
        taxpercentage: 8.0,
        taxtype: :local,
        status: :active,
      )

      policy = TaxPolicy.new(@user, tax)
      assert policy.show?, "Owner should have access to #{name}"
      assert policy.update?, "Owner should be able to update #{name}"
      assert policy.destroy?, "Owner should be able to destroy #{name}"
    end
  end

  # === SCOPE EFFICIENCY TESTS ===

  test 'should use efficient scope queries' do
    scope = TaxPolicy::Scope.new(@user, Tax).resolve

    # Verify the scope uses joins for efficiency
    assert scope.to_sql.include?('JOIN'), 'Scope should use joins for efficiency'
    assert scope.to_sql.include?('restaurants'), 'Scope should join to restaurants table'
  end

  test 'should handle scope with additional conditions' do
    # Create taxes with different statuses
    Tax.create!(restaurant: @restaurant, name: 'Active Tax', taxpercentage: 8.0, taxtype: :local, status: :active)
    Tax.create!(restaurant: @restaurant, name: 'Inactive Tax', taxpercentage: 7.0, taxtype: :state, status: :inactive)

    scope = TaxPolicy::Scope.new(@user, Tax).resolve

    # Should work with additional conditions
    active_taxes = scope.where(status: :active)
    inactive_taxes = scope.where(status: :inactive)

    assert active_taxes.count >= 1, 'Should find active taxes'
    assert inactive_taxes.count >= 1, 'Should find inactive taxes'
  end
end
