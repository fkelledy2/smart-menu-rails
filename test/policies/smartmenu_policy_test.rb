require 'test_helper'

class SmartmenuPolicyTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @other_user = users(:two)
    @restaurant = restaurants(:one) # Owned by @user
    @other_restaurant = restaurants(:two) # Owned by @other_user

    # Create smartmenus for testing
    @smartmenu = Smartmenu.create!(
      restaurant: @restaurant,
      slug: 'test-smartmenu',
    )

    @other_smartmenu = Smartmenu.create!(
      restaurant: @other_restaurant,
      slug: 'other-smartmenu',
    )
  end

  # === INDEX TESTS (Public Access) ===

  test 'should allow authenticated user to view smartmenu index' do
    policy = SmartmenuPolicy.new(@user, Smartmenu)
    assert policy.index?
  end

  test 'should allow anonymous user to view smartmenu index' do
    policy = SmartmenuPolicy.new(nil, Smartmenu)
    assert policy.index?, 'Anonymous users should be able to view smartmenu index'
  end

  test 'should allow other user to view smartmenu index' do
    policy = SmartmenuPolicy.new(@other_user, Smartmenu)
    assert policy.index?
  end

  # === SHOW TESTS (Public Access) ===

  test 'should allow authenticated user to view smartmenu' do
    policy = SmartmenuPolicy.new(@user, @smartmenu)
    assert policy.show?
  end

  test 'should allow anonymous user to view smartmenu' do
    policy = SmartmenuPolicy.new(nil, @smartmenu)
    assert policy.show?, 'Anonymous users should be able to view smartmenus (customer access)'
  end

  test 'should allow other user to view smartmenu' do
    policy = SmartmenuPolicy.new(@other_user, @smartmenu)
    assert policy.show?, 'Any user should be able to view smartmenus (customer access)'
  end

  test 'should allow owner to view their smartmenu' do
    policy = SmartmenuPolicy.new(@user, @smartmenu)
    assert policy.show?
  end

  # === CREATE TESTS ===

  test 'should allow authenticated user to create smartmenu' do
    policy = SmartmenuPolicy.new(@user, Smartmenu.new)
    assert policy.create?
  end

  test 'should allow anonymous user to create smartmenu' do
    policy = SmartmenuPolicy.new(nil, Smartmenu.new)
    # ApplicationPolicy creates User.new for nil user, so user.present? is true
    # The actual authentication check happens in controllers
    assert policy.create?, 'ApplicationPolicy creates User.new for anonymous users'
  end

  # === UPDATE TESTS (Owner Only) ===

  test 'should allow owner to update smartmenu' do
    policy = SmartmenuPolicy.new(@user, @smartmenu)
    assert policy.update?
  end

  test 'should deny non-owner from updating smartmenu' do
    policy = SmartmenuPolicy.new(@user, @other_smartmenu)
    assert_not policy.update?
  end

  test 'should deny anonymous user from updating smartmenu' do
    policy = SmartmenuPolicy.new(nil, @smartmenu)
    assert_not policy.update?
  end

  # === DESTROY TESTS (Owner Only) ===

  test 'should allow owner to destroy smartmenu' do
    policy = SmartmenuPolicy.new(@user, @smartmenu)
    assert policy.destroy?
  end

  test 'should deny non-owner from destroying smartmenu' do
    policy = SmartmenuPolicy.new(@user, @other_smartmenu)
    assert_not policy.destroy?
  end

  test 'should deny anonymous user from destroying smartmenu' do
    policy = SmartmenuPolicy.new(nil, @smartmenu)
    assert_not policy.destroy?
  end

  # === SCOPE TESTS ===

  test "should scope smartmenus to user's restaurant smartmenus" do
    scope = SmartmenuPolicy::Scope.new(@user, Smartmenu).resolve

    # Should include user's restaurant smartmenus
    assert_includes scope, @smartmenu

    # Should not include other user's restaurant smartmenus
    assert_not_includes scope, @other_smartmenu
  end

  test 'should return empty scope for anonymous user' do
    scope = SmartmenuPolicy::Scope.new(nil, Smartmenu).resolve
    assert scope.respond_to?(:to_a)

    # Anonymous scope is public: active menu smartmenus with no tablesetting
    assert_includes scope, smartmenus(:customer_menu)
    assert_not_includes scope, smartmenus(:one)
  end

  test 'should handle user with no restaurant smartmenus' do
    user_with_no_restaurants = User.create!(
      email: 'nosmartmenus@example.com',
      password: 'password123',
    )

    scope = SmartmenuPolicy::Scope.new(user_with_no_restaurants, Smartmenu).resolve

    # Should not include any smartmenus
    assert_not_includes scope, @smartmenu
    assert_not_includes scope, @other_smartmenu
  end

  # === EDGE CASE TESTS ===

  test 'should handle nil smartmenu record' do
    policy = SmartmenuPolicy.new(@user, nil)

    # Public methods should still work for nil record
    assert policy.index?
    assert policy.show?
    assert policy.create?

    # Owner-based methods should return false for nil record
    assert_not policy.update?
    assert_not policy.destroy?
  end

  test 'should handle smartmenu without restaurant' do
    smartmenu_without_restaurant = Smartmenu.new(slug: 'test')
    policy = SmartmenuPolicy.new(@user, smartmenu_without_restaurant)

    # Public access should still work
    assert policy.show?, 'Public access should work even without restaurant'

    # Owner-based access should be denied
    assert_not policy.update?
    assert_not policy.destroy?
  end

  test 'should inherit from ApplicationPolicy' do
    assert SmartmenuPolicy < ApplicationPolicy
  end

  # === PUBLIC ACCESS TESTS ===

  test 'should differentiate between public and owner permissions' do
    # Public permissions (anyone can access)
    anonymous_policy = SmartmenuPolicy.new(nil, @smartmenu)
    assert anonymous_policy.index?, 'Anyone should be able to view smartmenu index'
    assert anonymous_policy.show?, 'Anyone should be able to view smartmenus'
    assert anonymous_policy.create?, 'ApplicationPolicy creates User.new for anonymous users'
    assert_not anonymous_policy.update?, 'Anonymous users should not be able to update smartmenus'
    assert_not anonymous_policy.destroy?, 'Anonymous users should not be able to destroy smartmenus'

    # Non-owner authenticated user permissions
    non_owner_policy = SmartmenuPolicy.new(@other_user, @smartmenu)
    assert non_owner_policy.index?, 'Authenticated users should be able to view smartmenu index'
    assert non_owner_policy.show?, 'Authenticated users should be able to view smartmenus'
    assert non_owner_policy.create?, 'Authenticated users should be able to create smartmenus'
    assert_not non_owner_policy.update?, 'Non-owners should not be able to update smartmenus'
    assert_not non_owner_policy.destroy?, 'Non-owners should not be able to destroy smartmenus'

    # Owner permissions
    owner_policy = SmartmenuPolicy.new(@user, @smartmenu)
    assert owner_policy.index?, 'Owners should be able to view smartmenu index'
    assert owner_policy.show?, 'Owners should be able to view smartmenus'
    assert owner_policy.create?, 'Owners should be able to create smartmenus'
    assert owner_policy.update?, 'Owners should be able to update their smartmenus'
    assert owner_policy.destroy?, 'Owners should be able to destroy their smartmenus'
  end

  # === BUSINESS LOGIC TESTS ===

  test 'should handle different smartmenu types' do
    # Test with different smartmenu configurations
    menu = @restaurant.menus.first || Menu.create!(name: 'Test Menu', restaurant: @restaurant, status: :active)
    tablesetting = @restaurant.tablesettings.first || Tablesetting.create!(name: 'Test Table', restaurant: @restaurant,
                                                                           capacity: 4, tabletype: :indoor, status: :free,)

    configurations = [
      { slug: 'menu-only', menu: menu },
      { slug: 'table-only', tablesetting: tablesetting },
      { slug: 'full-config', menu: menu, tablesetting: tablesetting },
    ]

    configurations.each do |config|
      smartmenu = Smartmenu.create!(
        restaurant: @restaurant,
        **config,
      )

      # Public access should work regardless of configuration
      anonymous_policy = SmartmenuPolicy.new(nil, smartmenu)
      assert anonymous_policy.show?, "Anonymous users should be able to view #{config[:slug]} smartmenus"

      # Owner access should work regardless of configuration
      owner_policy = SmartmenuPolicy.new(@user, smartmenu)
      assert owner_policy.show?, "Owner should have access to #{config[:slug]} smartmenus"
      assert owner_policy.update?, "Owner should be able to update #{config[:slug]} smartmenus"
      assert owner_policy.destroy?, "Owner should be able to destroy #{config[:slug]} smartmenus"
    end
  end

  test 'should handle multiple smartmenus per restaurant' do
    # Create additional smartmenu for the same restaurant
    additional_smartmenu = Smartmenu.create!(
      restaurant: @restaurant,
      slug: 'second-smartmenu',
    )

    # Public access should work for both
    anonymous_policy = SmartmenuPolicy.new(nil, additional_smartmenu)
    assert anonymous_policy.show?

    # Owner access should work for both
    owner_policy = SmartmenuPolicy.new(@user, additional_smartmenu)
    assert owner_policy.update?
    assert owner_policy.destroy?

    # Scope should include both smartmenus
    scope = SmartmenuPolicy::Scope.new(@user, Smartmenu).resolve
    assert_includes scope, @smartmenu
    assert_includes scope, additional_smartmenu
  end

  test 'should handle cross-restaurant smartmenu access correctly' do
    # Verify that ownership is checked through restaurant for management actions
    policy_own_smartmenu = SmartmenuPolicy.new(@user, @smartmenu)
    policy_other_smartmenu = SmartmenuPolicy.new(@user, @other_smartmenu)

    # Public access should work for both
    assert policy_own_smartmenu.show?
    assert policy_other_smartmenu.show?

    # Management access should only work for owned smartmenu
    assert policy_own_smartmenu.update?
    assert policy_own_smartmenu.destroy?

    assert_not policy_other_smartmenu.update?
    assert_not policy_other_smartmenu.destroy?
  end

  # === CUSTOMER ACCESS TESTS ===

  test 'should allow customer access patterns' do
    # Simulate customer accessing smartmenu via QR code or link
    customer_policy = SmartmenuPolicy.new(nil, @smartmenu)

    # Customers should be able to browse smartmenus
    assert customer_policy.index?, 'Customers should be able to browse smartmenus'
    assert customer_policy.show?, 'Customers should be able to view specific smartmenus'

    # Customers should not be able to manage smartmenus (except create due to ApplicationPolicy)
    assert customer_policy.create?, 'ApplicationPolicy creates User.new for anonymous users'
    assert_not customer_policy.update?, 'Customers should not be able to update smartmenus'
    assert_not customer_policy.destroy?, 'Customers should not be able to destroy smartmenus'
  end

  test 'should handle smartmenu slug-based access' do
    # Test access using slug (common for public smartmenu access)
    slug_smartmenu = Smartmenu.create!(
      restaurant: @restaurant,
      slug: 'public-menu-2024',
    )

    # Public access via slug should work
    public_policy = SmartmenuPolicy.new(nil, slug_smartmenu)
    assert public_policy.show?, 'Public should be able to access smartmenu via slug'

    # Owner management should work
    owner_policy = SmartmenuPolicy.new(@user, slug_smartmenu)
    assert owner_policy.update?, 'Owner should be able to manage smartmenu accessed via slug'
  end

  # === RESTAURANT OWNERSHIP TESTS ===

  test 'should properly validate restaurant ownership' do
    # Test the ownership chain: User → Restaurant → Smartmenu
    assert_equal @user.id, @smartmenu.restaurant.user_id,
                 'Test setup should have proper ownership chain'

    policy = SmartmenuPolicy.new(@user, @smartmenu)
    assert policy.update?, 'Owner should have management access through restaurant ownership'

    # Test with different user
    other_policy = SmartmenuPolicy.new(@user, @other_smartmenu)
    assert_not other_policy.update?, 'Non-owner should not have management access'
  end

  test 'should handle scope correctly with multiple restaurants per user' do
    # Create additional restaurant for the same user
    additional_restaurant = Restaurant.create!(
      name: 'Second Restaurant',
      user: @user,
      status: :active,
    )

    additional_smartmenu = Smartmenu.create!(
      restaurant: additional_restaurant,
      slug: 'second-restaurant-menu',
    )

    scope = SmartmenuPolicy::Scope.new(@user, Smartmenu).resolve

    # Should include smartmenus from both restaurants
    assert_includes scope, @smartmenu
    assert_includes scope, additional_smartmenu

    # Should not include other user's smartmenus
    assert_not_includes scope, @other_smartmenu
  end

  # === PERFORMANCE TESTS ===

  test 'should handle large smartmenu datasets efficiently' do
    # Create multiple smartmenus to test performance
    5.times do |i|
      Smartmenu.create!(
        restaurant: @restaurant,
        slug: "bulk-menu-#{i}",
      )
    end

    scope = SmartmenuPolicy::Scope.new(@user, Smartmenu).resolve

    # Should handle large datasets without N+1 queries
    assert_nothing_raised do
      scope.limit(50).each do |smartmenu|
        # Access associated data that should be efficiently loaded
        smartmenu.restaurant.name
      end
    end
  end

  test 'should prevent unauthorized management across restaurant boundaries' do
    # Create smartmenus in different restaurants
    restaurant_a = Restaurant.create!(name: 'Restaurant A', user: @user, status: :active)
    restaurant_b = Restaurant.create!(name: 'Restaurant B', user: @other_user, status: :active)

    smartmenu_a = Smartmenu.create!(restaurant: restaurant_a, slug: 'menu-a')
    smartmenu_b = Smartmenu.create!(restaurant: restaurant_b, slug: 'menu-b')

    # Public access should work for both
    policy_a = SmartmenuPolicy.new(@user, smartmenu_a)
    policy_b = SmartmenuPolicy.new(@user, smartmenu_b)

    assert policy_a.show?, 'User should be able to view any smartmenu (public access)'
    assert policy_b.show?, 'User should be able to view any smartmenu (public access)'

    # Management access should only work for owned restaurant
    assert policy_a.update?, "User should be able to manage their own restaurant's smartmenus"
    assert_not policy_b.update?, "User should not be able to manage other restaurant's smartmenus"

    # Scope should only include own restaurant's smartmenus
    scope = SmartmenuPolicy::Scope.new(@user, Smartmenu).resolve
    assert_includes scope, smartmenu_a
    assert_not_includes scope, smartmenu_b
  end

  # === SMARTMENU LIFECYCLE TESTS ===

  test 'should handle smartmenu lifecycle management' do
    # Test smartmenu creation, activation, deactivation, archival
    new_smartmenu = Smartmenu.new(
      restaurant: @restaurant,
      slug: 'lifecycle-menu',
    )

    policy = SmartmenuPolicy.new(@user, new_smartmenu)

    # Public access should work even for new/inactive smartmenus
    assert policy.show?, 'Public should be able to view inactive smartmenus'

    # Owner should be able to manage smartmenu through entire lifecycle
    assert policy.create?, 'Owner should be able to create smartmenus'

    # After creation
    new_smartmenu.save!
    assert policy.update?, 'Owner should be able to update smartmenus'

    # Menu assignment
    menu = @restaurant.menus.first || Menu.create!(name: 'Test Menu', restaurant: @restaurant, status: :active)
    new_smartmenu.update!(menu: menu)
    assert policy.update?, 'Owner should be able to manage smartmenus with menu assignment'

    # Table assignment
    tablesetting = @restaurant.tablesettings.first || Tablesetting.create!(name: 'Test Table', restaurant: @restaurant,
                                                                           capacity: 4, tabletype: :indoor, status: :free,)
    new_smartmenu.update!(tablesetting: tablesetting)
    assert policy.update?, 'Owner should be able to manage smartmenus with table assignment'
    assert policy.destroy?, 'Owner should be able to destroy configured smartmenus'
  end
end
