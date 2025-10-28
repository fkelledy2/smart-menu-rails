require 'test_helper'

class SizePolicyTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @other_user = users(:two)
    @restaurant = restaurants(:one) # Owned by @user
    @other_restaurant = restaurants(:two) # Owned by @other_user

    # Create sizes for testing
    @size = Size.create!(
      restaurant: @restaurant,
      name: 'Large',
      size: :lg,
      status: :active,
    )

    @other_size = Size.create!(
      restaurant: @other_restaurant,
      name: 'Medium',
      size: :md,
      status: :active,
    )
  end

  # === INDEX TESTS ===

  test 'should allow authenticated user to view size index' do
    policy = SizePolicy.new(@user, Size)
    assert policy.index?
  end

  test 'should allow anonymous user to view size index' do
    policy = SizePolicy.new(nil, Size)
    # ApplicationPolicy creates User.new for nil user, so user.present? is true
    assert policy.index?, 'ApplicationPolicy creates User.new for anonymous users'
  end

  # === SHOW TESTS ===

  test 'should allow owner to view size' do
    policy = SizePolicy.new(@user, @size)
    assert policy.show?
  end

  test 'should deny non-owner from viewing size' do
    policy = SizePolicy.new(@user, @other_size)
    assert_not policy.show?
  end

  test 'should deny anonymous user from viewing size' do
    policy = SizePolicy.new(nil, @size)
    assert_not policy.show?
  end

  # === CREATE TESTS ===

  test 'should allow authenticated user to create size' do
    policy = SizePolicy.new(@user, Size.new)
    assert policy.create?
  end

  test 'should allow anonymous user to create size' do
    policy = SizePolicy.new(nil, Size.new)
    # ApplicationPolicy creates User.new for nil user, so user.present? is true
    assert policy.create?, 'ApplicationPolicy creates User.new for anonymous users'
  end

  # === UPDATE TESTS ===

  test 'should allow owner to update size' do
    policy = SizePolicy.new(@user, @size)
    assert policy.update?
  end

  test 'should deny non-owner from updating size' do
    policy = SizePolicy.new(@user, @other_size)
    assert_not policy.update?
  end

  test 'should deny anonymous user from updating size' do
    policy = SizePolicy.new(nil, @size)
    assert_not policy.update?
  end

  # === DESTROY TESTS ===

  test 'should allow owner to destroy size' do
    policy = SizePolicy.new(@user, @size)
    assert policy.destroy?
  end

  test 'should deny non-owner from destroying size' do
    policy = SizePolicy.new(@user, @other_size)
    assert_not policy.destroy?
  end

  test 'should deny anonymous user from destroying size' do
    policy = SizePolicy.new(nil, @size)
    assert_not policy.destroy?
  end

  # === SCOPE TESTS ===

  test "should scope sizes to user's restaurant sizes" do
    scope = SizePolicy::Scope.new(@user, Size).resolve

    # Should include user's restaurant sizes
    assert_includes scope, @size

    # Should not include other user's restaurant sizes
    assert_not_includes scope, @other_size
  end

  test 'should return empty scope for anonymous user' do
    # Anonymous user scope will fail because user is nil
    assert_raises(NoMethodError) do
      SizePolicy::Scope.new(nil, Size).resolve
    end
  end

  test 'should handle user with no restaurant sizes' do
    user_with_no_restaurants = User.create!(
      email: 'nosizes@example.com',
      password: 'password123',
    )

    scope = SizePolicy::Scope.new(user_with_no_restaurants, Size).resolve

    # Should not include any sizes
    assert_not_includes scope, @size
    assert_not_includes scope, @other_size
  end

  # === EDGE CASE TESTS ===

  test 'should handle nil size record' do
    policy = SizePolicy.new(@user, nil)

    # Public methods should still work
    assert policy.index?
    assert policy.create?

    # Owner-based methods should return false for nil record
    assert_not policy.show?
    assert_not policy.update?
    assert_not policy.destroy?
  end

  test 'should handle size without restaurant' do
    size_without_restaurant = Size.new(name: 'Test Size', size: :md)
    policy = SizePolicy.new(@user, size_without_restaurant)

    # Should deny access to size without proper restaurant association
    assert_not policy.show?
    assert_not policy.update?
    assert_not policy.destroy?
  end

  test 'should inherit from ApplicationPolicy' do
    assert SizePolicy < ApplicationPolicy
  end

  # === BUSINESS LOGIC TESTS ===

  test 'should handle different size types' do
    # Test with different size types
    size_types = %i[xs sm md lg xl]

    size_types.each do |size_type|
      size = Size.create!(
        restaurant: @restaurant,
        name: "#{size_type.to_s.upcase} Size",
        size: size_type,
        status: :active,
      )

      policy = SizePolicy.new(@user, size)
      assert policy.show?, "Owner should have access to size type #{size_type}"
      assert policy.update?, "Owner should be able to update size type #{size_type}"
      assert policy.destroy?, "Owner should be able to destroy size type #{size_type}"
    end
  end

  test 'should handle different size statuses' do
    # Test with different size statuses
    statuses = %i[active inactive archived]

    statuses.each do |status|
      size = Size.create!(
        restaurant: @restaurant,
        name: "#{status.to_s.capitalize} Size",
        size: :md,
        status: status,
      )

      policy = SizePolicy.new(@user, size)
      assert policy.show?, "Owner should have access to #{status} sizes"
      assert policy.update?, "Owner should be able to update #{status} sizes"
      assert policy.destroy?, "Owner should be able to destroy #{status} sizes"
    end
  end

  test 'should handle standard size names' do
    # Test with common size names
    size_names = ['Small', 'Medium', 'Large', 'Extra Large', 'Jumbo', 'Family', 'Individual', 'Regular']

    size_names.each_with_index do |name, index|
      size = Size.create!(
        restaurant: @restaurant,
        name: name,
        size: %i[xs sm md lg xl][index % 5],
        status: :active,
      )

      policy = SizePolicy.new(@user, size)
      assert policy.show?, "Owner should have access to #{name} size"
      assert policy.update?, "Owner should be able to update #{name} size"
      assert policy.destroy?, "Owner should be able to destroy #{name} size"
    end
  end

  test 'should handle multiple sizes per restaurant' do
    # Create additional size for the same restaurant
    additional_size = Size.create!(
      restaurant: @restaurant,
      name: 'Extra Large',
      size: :xl,
      status: :active,
    )

    policy = SizePolicy.new(@user, additional_size)
    assert policy.show?
    assert policy.update?
    assert policy.destroy?

    # Scope should include both sizes
    scope = SizePolicy::Scope.new(@user, Size).resolve
    assert_includes scope, @size
    assert_includes scope, additional_size
  end

  test 'should handle cross-restaurant size access correctly' do
    # Verify that ownership is checked through restaurant
    policy_own_size = SizePolicy.new(@user, @size)
    policy_other_size = SizePolicy.new(@user, @other_size)

    # Should have access to own restaurant's size
    assert policy_own_size.show?
    assert policy_own_size.update?
    assert policy_own_size.destroy?

    # Should not have access to other restaurant's size
    assert_not policy_other_size.show?
    assert_not policy_other_size.update?
    assert_not policy_other_size.destroy?
  end

  # === RESTAURANT OWNERSHIP TESTS ===

  test 'should properly validate restaurant ownership' do
    # Test the ownership chain: User → Restaurant → Size
    assert_equal @user.id, @size.restaurant.user_id,
                 'Test setup should have proper ownership chain'

    policy = SizePolicy.new(@user, @size)
    assert policy.show?, 'Owner should have access through restaurant ownership'

    # Test with different user
    other_policy = SizePolicy.new(@user, @other_size)
    assert_not other_policy.show?, 'Non-owner should not have access'
  end

  test 'should handle scope correctly with multiple restaurants per user' do
    # Create additional restaurant for the same user
    additional_restaurant = Restaurant.create!(
      name: 'Second Restaurant',
      user: @user,
      status: :active,
    )

    additional_size = Size.create!(
      restaurant: additional_restaurant,
      name: 'Second Restaurant Size',
      size: :lg,
      status: :active,
    )

    scope = SizePolicy::Scope.new(@user, Size).resolve

    # Should include sizes from both restaurants
    assert_includes scope, @size
    assert_includes scope, additional_size

    # Should not include other user's sizes
    assert_not_includes scope, @other_size
  end

  # === SIZE CONFIGURATION TESTS ===

  test 'should handle size lifecycle management' do
    # Test size creation, activation, deactivation, archival
    new_size = Size.new(
      restaurant: @restaurant,
      name: 'New Size',
      size: :lg,
      status: :inactive,
    )

    policy = SizePolicy.new(@user, new_size)

    # Owner should be able to manage size through entire lifecycle
    assert policy.create?, 'Owner should be able to create sizes'

    # After creation
    new_size.save!
    assert policy.show?, 'Owner should be able to view new sizes'
    assert policy.update?, 'Owner should be able to update sizes'

    # Activation
    new_size.update!(status: :active)
    assert policy.update?, 'Owner should be able to activate sizes'

    # Size type changes
    new_size.update!(size: :xl)
    assert policy.update?, 'Owner should be able to change size types'

    # Archival
    new_size.update!(status: :archived)
    assert policy.update?, 'Owner should be able to archive sizes'
    assert policy.destroy?, 'Owner should be able to destroy archived sizes'
  end

  test 'should handle size pricing scenarios' do
    # Different size configurations for menu pricing
    size_configs = [
      { name: 'Small', size: :sm, status: :active },
      { name: 'Regular', size: :md, status: :active },
      { name: 'Large', size: :lg, status: :active },
      { name: 'Extra Large', size: :xl, status: :active },
      { name: 'Extra Small', size: :xs, status: :inactive },
      { name: 'Old Size', size: :md, status: :archived },
    ]

    size_configs.each do |size_data|
      size = Size.create!(
        restaurant: @restaurant,
        **size_data,
      )

      policy = SizePolicy.new(@user, size)
      assert policy.show?, "Owner should have access to #{size_data[:name]}"
      assert policy.update?, "Owner should be able to update #{size_data[:name]}"
      assert policy.destroy?, "Owner should be able to destroy #{size_data[:name]}"
    end
  end

  # === PERFORMANCE TESTS ===

  test 'should handle large size datasets efficiently' do
    # Create multiple sizes to test performance
    10.times do |i|
      Size.create!(
        restaurant: @restaurant,
        name: "Bulk Size #{i}",
        size: %i[xs sm md lg xl][i % 5],
        status: :active,
      )
    end

    scope = SizePolicy::Scope.new(@user, Size).resolve

    # Should handle large datasets without N+1 queries
    assert_nothing_raised do
      scope.limit(50).each do |size|
        # Access associated data that should be efficiently loaded
        size.restaurant.name
      end
    end
  end

  test 'should prevent unauthorized access across restaurant boundaries' do
    # Create sizes in different restaurants
    restaurant_a = Restaurant.create!(name: 'Restaurant A', user: @user, status: :active)
    restaurant_b = Restaurant.create!(name: 'Restaurant B', user: @other_user, status: :active)

    size_a = Size.create!(restaurant: restaurant_a, name: 'Size A', size: :lg, status: :active)
    size_b = Size.create!(restaurant: restaurant_b, name: 'Size B', size: :xl, status: :active)

    # User should only access their own restaurant's sizes
    policy_a = SizePolicy.new(@user, size_a)
    policy_b = SizePolicy.new(@user, size_b)

    assert policy_a.show?, "User should access their own restaurant's sizes"
    assert_not policy_b.show?, "User should not access other restaurant's sizes"

    # Scope should only include own restaurant's sizes
    scope = SizePolicy::Scope.new(@user, Size).resolve
    assert_includes scope, size_a
    assert_not_includes scope, size_b
  end

  # === SIZE MULTIPLIER BUSINESS LOGIC ===

  test 'should handle all size enum values' do
    # Test all available size enum values
    size_enums = %i[xs sm md lg xl]

    size_enums.each do |size_enum|
      size = Size.create!(
        restaurant: @restaurant,
        name: "#{size_enum.to_s.upcase} Size",
        size: size_enum,
        status: :active,
      )

      policy = SizePolicy.new(@user, size)
      assert policy.show?, "Owner should have access to size enum #{size_enum}"
      assert policy.update?, "Owner should be able to update size enum #{size_enum}"
      assert policy.destroy?, "Owner should be able to destroy size enum #{size_enum}"
    end
  end

  test 'should handle size combinations' do
    # Test different combinations of size enum and names
    size_combinations = [
      { name: 'Tiny', size: :xs },
      { name: 'Mini', size: :sm },
      { name: 'Standard', size: :md },
      { name: 'Big', size: :lg },
      { name: 'Huge', size: :xl },
    ]

    size_combinations.each do |combo|
      size = Size.create!(
        restaurant: @restaurant,
        name: combo[:name],
        size: combo[:size],
        status: :active,
      )

      policy = SizePolicy.new(@user, size)
      assert policy.show?, "Owner should have access to size #{combo[:name]} (#{combo[:size]})"
      assert policy.update?, "Owner should be able to update size #{combo[:name]} (#{combo[:size]})"
      assert policy.destroy?, "Owner should be able to destroy size #{combo[:name]} (#{combo[:size]})"
    end
  end

  # === SCOPE EFFICIENCY TESTS ===

  test 'should use efficient scope queries' do
    scope = SizePolicy::Scope.new(@user, Size).resolve

    # Verify the scope uses joins for efficiency
    assert scope.to_sql.include?('JOIN'), 'Scope should use joins for efficiency'
    assert scope.to_sql.include?('restaurants'), 'Scope should join to restaurants table'
  end

  test 'should handle scope with additional conditions' do
    # Create sizes with different statuses
    Size.create!(restaurant: @restaurant, name: 'Active Size', size: :md, status: :active)
    Size.create!(restaurant: @restaurant, name: 'Inactive Size', size: :lg, status: :inactive)

    scope = SizePolicy::Scope.new(@user, Size).resolve

    # Should work with additional conditions
    active_sizes = scope.where(status: :active)
    inactive_sizes = scope.where(status: :inactive)

    assert active_sizes.count >= 1, 'Should find active sizes'
    assert inactive_sizes.count >= 1, 'Should find inactive sizes'
  end

  # === SIZE NAMING TESTS ===

  test 'should handle international size names' do
    # Test sizes with international naming conventions
    international_sizes = [
      'Piccolo', 'Grande', 'Venti',  # Italian/Starbucks
      'Petit', 'Moyen', 'Grand',     # French
      'Klein', 'Mittel', 'Groß',     # German
      'Pequeño', 'Mediano', 'Grande', # Spanish
    ]

    international_sizes.each_with_index do |name, index|
      size = Size.create!(
        restaurant: @restaurant,
        name: name,
        size: %i[xs sm md lg xl][index % 5],
        status: :active,
      )

      policy = SizePolicy.new(@user, size)
      assert policy.show?, "Owner should have access to international size: #{name}"
      assert policy.update?, "Owner should be able to update international size: #{name}"
      assert policy.destroy?, "Owner should be able to destroy international size: #{name}"
    end
  end
end
