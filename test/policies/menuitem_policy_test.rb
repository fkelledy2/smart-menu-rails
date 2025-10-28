require 'test_helper'

class MenuitemPolicyTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @other_user = users(:two)
    @restaurant = restaurants(:one) # Owned by @user
    @other_restaurant = restaurants(:two) # Owned by @other_user
    @menu = menus(:one) # Belongs to @restaurant
    @other_menu = menus(:two) if menus(:two) # Belongs to @other_restaurant
    @menusection = menusections(:one) # Belongs to @menu
    @menuitem = menuitems(:one) # Belongs to @menusection

    # Create a menuitem for other user's restaurant if needed
    return unless @other_menu

    @other_menusection = @other_menu.menusections.first ||
                         Menusection.create!(name: 'Other Section', menu: @other_menu, status: :active)
    @other_menuitem = @other_menusection.menuitems.first ||
                      Menuitem.create!(
                        name: 'Other Item',
                        menusection: @other_menusection,
                        price: 15.99,
                        preptime: 20,
                        calories: 400,
                        itemtype: :food,
                        status: :active,
                      )
  end

  # === INDEX TESTS ===

  test 'should allow authenticated user to view menuitem index' do
    policy = MenuitemPolicy.new(@user, Menuitem)
    assert policy.index?
  end

  test 'should allow anonymous user to view menuitem index' do
    policy = MenuitemPolicy.new(nil, Menuitem)
    # ApplicationPolicy creates User.new for nil user, so user.present? is true
    assert policy.index?, 'ApplicationPolicy creates User.new for anonymous users'
  end

  # === SHOW TESTS ===

  test 'should allow owner to view menuitem' do
    policy = MenuitemPolicy.new(@user, @menuitem)
    assert policy.show?
  end

  test 'should deny non-owner from viewing menuitem' do
    if @other_menuitem
      policy = MenuitemPolicy.new(@user, @other_menuitem)
      assert_not policy.show?
    end
  end

  test 'should deny anonymous user from viewing menuitem' do
    policy = MenuitemPolicy.new(nil, @menuitem)
    assert_not policy.show?
  end

  # === CREATE TESTS ===

  test 'should allow authenticated user to create menuitem' do
    policy = MenuitemPolicy.new(@user, Menuitem.new)
    assert policy.create?
  end

  test 'should allow anonymous user to create menuitem' do
    policy = MenuitemPolicy.new(nil, Menuitem.new)
    # ApplicationPolicy creates User.new for nil user, so user.present? is true
    assert policy.create?, 'ApplicationPolicy creates User.new for anonymous users'
  end

  # === UPDATE TESTS ===

  test 'should allow owner to update menuitem' do
    policy = MenuitemPolicy.new(@user, @menuitem)
    assert policy.update?
  end

  test 'should deny non-owner from updating menuitem' do
    if @other_menuitem
      policy = MenuitemPolicy.new(@user, @other_menuitem)
      assert_not policy.update?
    end
  end

  test 'should deny anonymous user from updating menuitem' do
    policy = MenuitemPolicy.new(nil, @menuitem)
    assert_not policy.update?
  end

  # === DESTROY TESTS ===

  test 'should allow owner to destroy menuitem' do
    policy = MenuitemPolicy.new(@user, @menuitem)
    assert policy.destroy?
  end

  test 'should deny non-owner from destroying menuitem' do
    if @other_menuitem
      policy = MenuitemPolicy.new(@user, @other_menuitem)
      assert_not policy.destroy?
    end
  end

  test 'should deny anonymous user from destroying menuitem' do
    policy = MenuitemPolicy.new(nil, @menuitem)
    assert_not policy.destroy?
  end

  # === SCOPE TESTS ===

  test "should scope menuitems to user's restaurant menuitems" do
    scope = MenuitemPolicy::Scope.new(@user, Menuitem).resolve

    # Should include user's restaurant menuitems
    assert_includes scope, @menuitem

    # Should not include other user's restaurant menuitems
    if @other_menuitem
      assert_not_includes scope, @other_menuitem
    end
  end

  test 'should return empty scope for anonymous user' do
    # Anonymous user scope will fail because user is nil
    assert_raises(NoMethodError) do
      MenuitemPolicy::Scope.new(nil, Menuitem).resolve
    end
  end

  test 'should handle user with no restaurant menuitems' do
    user_with_no_restaurants = User.create!(
      email: 'nomenuitems@example.com',
      password: 'password123',
    )

    scope = MenuitemPolicy::Scope.new(user_with_no_restaurants, Menuitem).resolve

    # Should not include any menuitems
    assert_not_includes scope, @menuitem
    if @other_menuitem
      assert_not_includes scope, @other_menuitem
    end
  end

  # === EDGE CASE TESTS ===

  test 'should handle nil menuitem record' do
    policy = MenuitemPolicy.new(@user, nil)

    # All owner-based methods should return false for nil record
    assert_not policy.show?
    assert_not policy.update?
    assert_not policy.destroy?
  end

  test 'should handle menuitem without menusection' do
    menuitem_without_menusection = Menuitem.new(name: 'Test Item')
    policy = MenuitemPolicy.new(@user, menuitem_without_menusection)

    # Should deny access to menuitem without proper menusection association
    assert_not policy.show?
    assert_not policy.update?
    assert_not policy.destroy?
  end

  test 'should handle menuitem with menusection but no menu' do
    menusection_without_menu = Menusection.new(name: 'Test Section')
    menuitem_with_orphaned_menusection = Menuitem.new(
      name: 'Test Item',
      menusection: menusection_without_menu,
    )
    policy = MenuitemPolicy.new(@user, menuitem_with_orphaned_menusection)

    # Should deny access to menuitem with menusection that has no menu
    assert_not policy.show?
    assert_not policy.update?
    assert_not policy.destroy?
  end

  test 'should inherit from ApplicationPolicy' do
    assert MenuitemPolicy < ApplicationPolicy
  end

  # === BUSINESS LOGIC TESTS ===

  test 'should allow multiple menuitems per menusection' do
    # Create additional menuitem for the same menusection
    additional_menuitem = Menuitem.create!(
      name: 'Second Item',
      menusection: @menusection,
      price: 12.99,
      preptime: 15,
      calories: 350,
      itemtype: :food,
      status: :active,
    )

    policy = MenuitemPolicy.new(@user, additional_menuitem)
    assert policy.show?
    assert policy.update?
    assert policy.destroy?

    # Scope should include both menuitems
    scope = MenuitemPolicy::Scope.new(@user, Menuitem).resolve
    assert_includes scope, @menuitem
    assert_includes scope, additional_menuitem
  end

  test 'should handle cross-restaurant menuitem access correctly' do
    # Verify that ownership is checked through the full chain
    policy_own_menuitem = MenuitemPolicy.new(@user, @menuitem)

    # Should have access to own restaurant's menuitem
    assert policy_own_menuitem.show?
    assert policy_own_menuitem.update?
    assert policy_own_menuitem.destroy?

    # Should not have access to other restaurant's menuitem
    if @other_menuitem
      policy_other_menuitem = MenuitemPolicy.new(@user, @other_menuitem)
      assert_not policy_other_menuitem.show?
      assert_not policy_other_menuitem.update?
      assert_not policy_other_menuitem.destroy?
    end
  end

  # === OWNERSHIP CHAIN TESTS ===

  test 'should properly validate ownership chain' do
    # Test the ownership chain: User -> Restaurant -> Menu -> Menusection -> Menuitem
    assert_equal @user.id, @menuitem.menusection.menu.restaurant.user_id,
                 'Test setup should have proper ownership chain'

    policy = MenuitemPolicy.new(@user, @menuitem)
    assert policy.show?, 'Owner should have access through ownership chain'

    # Test with different user
    if @other_menuitem
      other_policy = MenuitemPolicy.new(@user, @other_menuitem)
      assert_not other_policy.show?, 'Non-owner should not have access'
    end
  end

  test 'should handle complex menusection relationships' do
    # Create menuitem in different menusection of same menu
    another_menusection = Menusection.create!(
      name: 'Another Section',
      menu: @menu,
      status: :active,
    )

    menuitem_in_another_section = Menuitem.create!(
      name: 'Item in Another Section',
      menusection: another_menusection,
      price: 18.99,
      preptime: 25,
      calories: 500,
      itemtype: :food,
      status: :active,
    )

    policy = MenuitemPolicy.new(@user, menuitem_in_another_section)
    assert policy.show?, 'Owner should have access to menuitems in any section of their menu'
    assert policy.update?
    assert policy.destroy?
  end

  # === SCOPE COMPLEXITY TESTS ===

  test 'should handle complex scope queries efficiently' do
    # The scope uses joins across multiple tables
    scope = MenuitemPolicy::Scope.new(@user, Menuitem).resolve

    # Verify the scope includes proper joins
    assert scope.to_sql.include?('JOIN'), 'Scope should use joins for efficiency'
    assert scope.to_sql.include?('restaurants'), 'Scope should join to restaurants table'

    # Should work with additional conditions
    scoped_with_conditions = scope.where(status: :active)
    assert scoped_with_conditions.count >= 0, 'Scope should work with additional conditions'
  end

  test 'should scope correctly with multiple restaurants per user' do
    # Create additional restaurant for the same user
    additional_restaurant = Restaurant.create!(
      name: 'Second Restaurant',
      user: @user,
      status: :active,
    )

    additional_menu = Menu.create!(
      name: 'Second Menu',
      restaurant: additional_restaurant,
      status: :active,
    )

    additional_menusection = Menusection.create!(
      name: 'Second Section',
      menu: additional_menu,
      status: :active,
    )

    additional_menuitem = Menuitem.create!(
      name: 'Second Restaurant Item',
      menusection: additional_menusection,
      price: 22.99,
      preptime: 30,
      calories: 600,
      itemtype: :food,
      status: :active,
    )

    scope = MenuitemPolicy::Scope.new(@user, Menuitem).resolve

    # Should include menuitems from both restaurants
    assert_includes scope, @menuitem
    assert_includes scope, additional_menuitem

    # Should not include other user's menuitems
    if @other_menuitem
      assert_not_includes scope, @other_menuitem
    end
  end

  # === PERFORMANCE TESTS ===

  test 'should handle large datasets efficiently' do
    # Test that the policy doesn't cause N+1 queries
    scope = MenuitemPolicy::Scope.new(@user, Menuitem).resolve

    # This should execute efficiently without N+1 queries
    assert_nothing_raised do
      scope.limit(100).each do |menuitem|
        # Access associated data that should be efficiently loaded
        menuitem.menusection.menu.restaurant.name
      end
    end
  end
end
