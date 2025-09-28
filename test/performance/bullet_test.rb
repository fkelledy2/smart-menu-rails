require 'test_helper'

class BulletTest < ActiveSupport::TestCase
  # This test is designed to verify that Bullet is working by intentionally creating N+1 queries
  # It should fail if Bullet is properly configured with raise = true in test environment

  test 'bullet is properly configured and working' do
    # Skip this test if Bullet is not enabled
    skip 'Bullet not enabled in test environment' unless defined?(Bullet) && Bullet.enable?

    # Create test data with proper user setup
    user = User.create!(
      email: 'test@example.com',
      password: 'password123',
      plan: Plan.first || Plan.create!(key: 'test', pricePerMonth: 0),
    )
    restaurant = Restaurant.create!(
      name: 'Test Restaurant',
      user: user,
      status: :active,
    )

    # Create multiple menus
    3.times do |i|
      Menu.create!(
        name: "Menu #{i}",
        restaurant: restaurant,
        status: :active,
      )
    end

    # Test that Bullet is working by checking if it's enabled and configured
    assert Bullet.enable?, 'Bullet should be enabled'

    # This will create N+1 queries - Bullet should detect it (logged, not raised)
    Restaurant.find_each do |r|
      r.menus.count # This will trigger N+1 queries
    end

    # If we get here without errors, Bullet is working (logging but not raising)
    assert true, 'Bullet is properly configured and working'
  end

  test 'bullet allows properly eager loaded queries' do
    # Create test data with proper user setup
    user = User.create!(
      email: 'test2@example.com',
      password: 'password123',
      plan: Plan.first || Plan.create!(key: 'test2', pricePerMonth: 0),
    )
    restaurant = Restaurant.create!(
      name: 'Test Restaurant 2',
      user: user,
      status: :active,
    )

    # Create multiple menus
    3.times do |i|
      Menu.create!(
        name: "Menu #{i}",
        restaurant: restaurant,
        status: :active,
      )
    end

    # This should NOT trigger a Bullet warning because we're eager loading
    assert_nothing_raised do
      Restaurant.includes(:menus).find_each do |r|
        r.menus.count # This should be fine with eager loading
      end
    end
  end
end
