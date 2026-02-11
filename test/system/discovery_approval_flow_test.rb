require 'application_system_test_case'

class DiscoveryApprovalFlowTest < ApplicationSystemTestCase
  test 'admin can view discovery queue and approve a restaurant with auto-published preview' do
    # Setup admin user
    admin = User.create!(
      email: 'admin@mellow.menu',
      password: 'password123',
      password_confirmation: 'password123',
      first_name: 'Admin',
      last_name: 'User',
    )
    admin.update!(admin: true, super_admin: true)

    # Create a discovered restaurant
    dr = DiscoveredRestaurant.create!(
      name: 'Test Pizzeria',
      city_name: 'Dublin',
      google_place_id: "test_#{SecureRandom.hex(4)}",
      website_url: 'https://testpizzeria.ie',
      status: :pending,
      discovered_at: Time.current,
      metadata: {
        'place_details' => {
          'formatted_address' => '123 Main St, Dublin',
          'opening_hours' => [
            { 'day' => 1, 'open_hour' => 12, 'open_min' => 0, 'close_hour' => 22, 'close_min' => 0 },
            { 'day' => 2, 'open_hour' => 12, 'open_min' => 0, 'close_hour' => 22, 'close_min' => 0 },
            { 'day' => 3, 'open_hour' => 12, 'open_min' => 0, 'close_hour' => 22, 'close_min' => 0 },
            { 'day' => 4, 'open_hour' => 12, 'open_min' => 0, 'close_hour' => 22, 'close_min' => 0 },
            { 'day' => 5, 'open_hour' => 12, 'open_min' => 0, 'close_hour' => 23, 'close_min' => 0 },
            { 'day' => 6, 'open_hour' => 12, 'open_min' => 0, 'close_hour' => 23, 'close_min' => 0 },
          ],
        },
      },
    )

    # Login as admin
    visit new_user_session_path
    fill_testid('login-email-input', admin.email)
    fill_testid('login-password-input', 'password123')
    click_testid('login-submit-btn')

    # Navigate to discovery queue
    visit admin_discovered_restaurants_path
    assert_text 'Discovery Queue'
    assert_text 'Test Pizzeria'

    # View the discovered restaurant detail
    visit admin_discovered_restaurant_path(dr)
    assert_text 'Test Pizzeria'
    assert_text 'testpizzeria.ie'

    # Approve the restaurant
    click_on 'Approve'

    dr.reload
    assert dr.approved?, 'Discovered restaurant should be approved'

    # Verify restaurant was provisioned
    assert dr.restaurant.present?, 'Restaurant should be linked after approval'

    restaurant = dr.restaurant
    assert restaurant.unclaimed?, 'Provisioned restaurant should be unclaimed'
    assert_not restaurant.ordering_enabled?, 'Ordering should be disabled for unclaimed'
    assert_not restaurant.payments_enabled?, 'Payments should be disabled for unclaimed'
    assert restaurant.preview_enabled?, 'Preview should be auto-enabled on approve'
    assert restaurant.preview_published_at.present?, 'Preview published_at should be set on approve'

    # Verify opening hours were synced
    assert restaurant.restaurantavailabilities.count >= 6, 'Opening hours should be synced'

    monday = restaurant.restaurantavailabilities.find_by(dayofweek: :monday)
    assert monday.present?, 'Monday hours should exist'
    assert monday.open?, 'Monday should be open'
    assert_equal 12, monday.starthour
    assert_equal 22, monday.endhour
  end

  test 'admin can view source rules and create a blacklist entry' do
    admin = User.create!(
      email: 'admin@mellow.menu',
      password: 'password123',
      password_confirmation: 'password123',
      first_name: 'Admin',
      last_name: 'User',
    )
    admin.update!(admin: true, super_admin: true)

    visit new_user_session_path
    fill_testid('login-email-input', admin.email)
    fill_testid('login-password-input', 'password123')
    click_testid('login-submit-btn')

    visit admin_crawl_source_rules_path
    assert_text 'Source Rules'

    click_on 'New Rule'
    assert_text 'New Source Rule'

    fill_in 'Domain', with: 'deliveroo.ie'
    select 'Blacklist', from: 'Rule type'
    fill_in 'Reason', with: 'Delivery platform'
    click_on 'Create Rule'

    assert_text 'Blacklist rule created for deliveroo.ie'
    assert CrawlSourceRule.blacklisted?('deliveroo.ie')
  end

  test 'admin can view approved imports screen' do
    admin = User.create!(
      email: 'admin@mellow.menu',
      password: 'password123',
      password_confirmation: 'password123',
      first_name: 'Admin',
      last_name: 'User',
    )
    admin.update!(admin: true, super_admin: true)

    # Create an approved discovered restaurant with a linked restaurant
    restaurant = Restaurant.create!(
      name: 'Approved Place',
      user: admin,
      status: :active,
      claim_status: :unclaimed,
      preview_enabled: true,
      preview_published_at: Time.current,
    )

    DiscoveredRestaurant.create!(
      name: 'Approved Place',
      city_name: 'Dublin',
      google_place_id: "approved_#{SecureRandom.hex(4)}",
      status: :approved,
      restaurant: restaurant,
      metadata: {},
    )

    visit new_user_session_path
    fill_testid('login-email-input', admin.email)
    fill_testid('login-password-input', 'password123')
    click_testid('login-submit-btn')

    visit approved_imports_admin_discovered_restaurants_path
    assert_text 'Approved Imports'
    assert_text 'Approved Place'
    assert_text 'Published'
  end
end
