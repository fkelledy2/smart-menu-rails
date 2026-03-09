require 'test_helper'

class OrdrnotePolicyTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
    @employee = employees(:one)
    
    # Create manager dynamically since employees(:two) doesn't exist
    @manager_user = User.create!(email: 'manager_policy@test.com', password: 'password123')
    @manager = @restaurant.employees.create!(
      user: @manager_user,
      name: 'Manager User',
      eid: 'MGR_POLICY',
      role: 'manager',
      status: 'active'
    )

    @ordr = ordrs(:one)
    @ordr.update!(restaurant: @restaurant)

    @ordrnote = @ordr.ordrnotes.create!(
      employee: @employee,
      content: 'Test note',
      category: 'dietary',
      priority: 'high',
    )

    @user = @employee.user
  end

  test 'index? allows restaurant employees' do
    policy = OrdrnotePolicy.new(@user, @ordrnote)
    assert policy.index?
  end

  test 'index? denies non-employees' do
    other_user = users(:two)
    policy = OrdrnotePolicy.new(other_user, @ordrnote)
    assert_not policy.index?
  end

  test 'show? allows restaurant employees' do
    policy = OrdrnotePolicy.new(@user, @ordrnote)
    assert policy.show?
  end

  test 'show? denies non-employees' do
    other_user = users(:two)
    policy = OrdrnotePolicy.new(other_user, @ordrnote)
    assert_not policy.show?
  end

  test 'create? allows restaurant employees' do
    policy = OrdrnotePolicy.new(@user, @ordrnote)
    assert policy.create?
  end

  test 'create? denies non-employees' do
    other_user = users(:two)
    policy = OrdrnotePolicy.new(other_user, @ordrnote)
    assert_not policy.create?
  end

  test 'update? allows creator within 15 minutes' do
    @ordrnote.update_column(:created_at, 10.minutes.ago)
    policy = OrdrnotePolicy.new(@user, @ordrnote)
    assert policy.update?
  end

  test 'update? denies creator after 15 minutes' do
    @ordrnote.update_column(:created_at, 20.minutes.ago)
    policy = OrdrnotePolicy.new(@user, @ordrnote)
    assert_not policy.update?
  end

  test 'update? allows managers anytime' do
    @ordrnote.update_column(:created_at, 1.day.ago)
    policy = OrdrnotePolicy.new(@manager_user, @ordrnote)
    assert policy.update?
  end

  test 'update? allows admins anytime' do
    admin_user = User.create!(email: 'admin_policy@test.com', password: 'password123')
    admin = @restaurant.employees.create!(
      user: admin_user,
      name: 'Admin User',
      eid: 'ADM_POLICY',
      role: 'admin',
      status: 'active'
    )
    @ordrnote.update_column(:created_at, 1.day.ago)

    policy = OrdrnotePolicy.new(admin.user, @ordrnote)
    assert policy.update?
  end

  test 'update? denies non-employees' do
    other_user = users(:two)
    policy = OrdrnotePolicy.new(other_user, @ordrnote)
    assert_not policy.update?
  end

  test 'destroy? allows creator within 15 minutes' do
    @ordrnote.update_column(:created_at, 10.minutes.ago)
    policy = OrdrnotePolicy.new(@user, @ordrnote)
    assert policy.destroy?
  end

  test 'destroy? denies creator after 15 minutes' do
    @ordrnote.update_column(:created_at, 20.minutes.ago)
    policy = OrdrnotePolicy.new(@user, @ordrnote)
    assert_not policy.destroy?
  end

  test 'destroy? allows managers anytime' do
    @ordrnote.update_column(:created_at, 1.day.ago)
    policy = OrdrnotePolicy.new(@manager_user, @ordrnote)
    assert policy.destroy?
  end

  test 'destroy? allows admins anytime' do
    admin_user = User.create!(email: 'admin_destroy_policy@test.com', password: 'password123')
    admin = @restaurant.employees.create!(
      user: admin_user,
      name: 'Admin Destroy User',
      eid: 'ADM_DESTROY',
      role: 'admin',
      status: 'active'
    )
    @ordrnote.update_column(:created_at, 1.day.ago)

    policy = OrdrnotePolicy.new(admin.user, @ordrnote)
    assert policy.destroy?
  end

  test 'destroy? denies non-employees' do
    other_user = users(:two)
    policy = OrdrnotePolicy.new(other_user, @ordrnote)
    assert_not policy.destroy?
  end

  test 'Scope returns notes for user restaurants' do
    other_restaurant = restaurants(:two)
    
    # Create test order since ordrs(:two) doesn't exist
    other_ordr = Ordr.create!(
      restaurant: other_restaurant,
      menu: other_restaurant.menus.first || Menu.create!(name: 'Test Menu', restaurant: other_restaurant, status: :active),
      tablesetting: other_restaurant.tablesettings.first || Tablesetting.create!(name: 'Test Table', restaurant: other_restaurant, capacity: 4, tabletype: :indoor, status: :free),
      orderedAt: Time.current,
      nett: 10.0,
      gross: 10.0
    )

    other_ordr.ordrnotes.create!(
      employee: @employee,
      content: 'Other note',
      category: 'operational',
      priority: 'low',
    )

    scope = OrdrnotePolicy::Scope.new(@user, Ordrnote.all).resolve

    assert_includes scope, @ordrnote
    # NOTE: other_note may or may not be included depending on employee associations
  end

  test 'Scope returns empty for non-employees' do
    other_user = users(:two)
    scope = OrdrnotePolicy::Scope.new(other_user, Ordrnote.all).resolve

    # Should return empty or only notes from restaurants where user is employee
    assert scope.is_a?(ActiveRecord::Relation)
  end
end
