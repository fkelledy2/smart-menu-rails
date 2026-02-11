require 'application_system_test_case'

class ClaimAndRemovalFlowTest < ApplicationSystemTestCase
  test 'public user can submit a removal request which unpublishes the preview' do
    admin = User.create!(
      email: 'admin@mellow.menu',
      password: 'password123',
      password_confirmation: 'password123',
      first_name: 'Admin',
      last_name: 'User',
    )

    restaurant = Restaurant.create!(
      name: 'My Restaurant',
      user: admin,
      status: :active,
      claim_status: :unclaimed,
      provisioned_by: :provisioned_by_system,
      preview_enabled: true,
      preview_published_at: Time.current,
    )

    visit new_restaurant_removal_request_path(restaurant)
    assert_text 'Request Removal'

    fill_in 'Email', with: 'owner@myrestaurant.com'
    fill_in 'Reason', with: 'I am the owner and did not consent to this listing'
    click_on 'Submit'

    assert_text 'removal request has been received'

    restaurant.reload
    assert_not restaurant.preview_enabled?, 'Preview should be disabled after removal request'
    assert_equal 1, RestaurantRemovalRequest.where(restaurant: restaurant).count
  end

  test 'public user can submit a claim request' do
    admin = User.create!(
      email: 'admin@mellow.menu',
      password: 'password123',
      password_confirmation: 'password123',
      first_name: 'Admin',
      last_name: 'User',
    )

    restaurant = Restaurant.create!(
      name: 'Unclaimed Bistro',
      user: admin,
      status: :active,
      claim_status: :unclaimed,
      provisioned_by: :provisioned_by_system,
      preview_enabled: true,
      preview_published_at: Time.current,
    )

    visit new_restaurant_claim_request_path(restaurant)
    assert_text 'Claim'

    fill_in 'Email', with: 'owner@unclaimedplace.com'
    fill_in 'Name', with: 'John Owner'
    click_on 'Submit'

    assert_text 'claim request has been submitted'

    assert_equal 1, RestaurantClaimRequest.where(restaurant: restaurant).count
    cr = RestaurantClaimRequest.last
    assert cr.started?
    assert_equal 'owner@unclaimedplace.com', cr.claimant_email
  end

  test 'admin can approve a claim request which soft-claims the restaurant' do
    admin = User.create!(
      email: 'admin@mellow.menu',
      password: 'password123',
      password_confirmation: 'password123',
      first_name: 'Admin',
      last_name: 'User',
    )
    admin.update!(admin: true, super_admin: true)

    restaurant = Restaurant.create!(
      name: 'Pending Claim Restaurant',
      user: admin,
      status: :active,
      claim_status: :unclaimed,
      provisioned_by: :provisioned_by_system,
    )

    cr = RestaurantClaimRequest.create!(
      restaurant: restaurant,
      claimant_email: 'claimer@example.com',
      claimant_name: 'Jane Claimer',
      verification_method: :email_domain,
      status: :started,
    )

    visit new_user_session_path
    fill_testid('login-email-input', admin.email)
    fill_testid('login-password-input', 'password123')
    click_testid('login-submit-btn')

    visit admin_restaurant_claim_requests_path
    assert_text 'Claim Requests'
    assert_text 'claimer@example.com'

    visit admin_restaurant_claim_request_path(cr)
    assert_text 'Pending Claim Restaurant'

    click_on 'Approve'

    cr.reload
    assert cr.approved?

    restaurant.reload
    assert restaurant.soft_claimed?, 'Restaurant should be soft_claimed after approval'
    assert_not restaurant.ordering_enabled?, 'Ordering should still be disabled (needs Stripe KYC)'
  end

  test 'admin can resolve a removal request' do
    admin = User.create!(
      email: 'admin@mellow.menu',
      password: 'password123',
      password_confirmation: 'password123',
      first_name: 'Admin',
      last_name: 'User',
    )
    admin.update!(admin: true, super_admin: true)

    restaurant = Restaurant.create!(
      name: 'Removed Restaurant',
      user: admin,
      status: :active,
      claim_status: :unclaimed,
      preview_enabled: false,
    )

    rr = RestaurantRemovalRequest.create!(
      restaurant: restaurant,
      requested_by_email: 'owner@removed.com',
      source: :public_page,
      status: :actioned_unpublished,
      reason: 'Remove my listing',
      actioned_at: Time.current,
      actioned_by_user: admin,
    )

    visit new_user_session_path
    fill_testid('login-email-input', admin.email)
    fill_testid('login-password-input', 'password123')
    click_testid('login-submit-btn')

    visit admin_restaurant_removal_requests_path
    assert_text 'Removal Requests'
    assert_text 'owner@removed.com'

    visit admin_restaurant_removal_request_path(rr)
    assert_text 'Removed Restaurant'

    click_on 'Resolve'

    rr.reload
    assert rr.resolved?
  end
end
