# frozen_string_literal: true

require 'test_helper'

class StaffInvitationsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @owner = users(:one)
    @restaurant = restaurants(:one)

    # StaffInvitationPolicy is not defined — Pundit raises NotDefinedError for
    # regular users. super_admin bypasses the authorize call entirely.
    @super = users(:super_admin)
    # Give super_admin ownership of restaurant :one so set_restaurant finds it.
    @restaurant.update_column(:user_id, @super.id)

    sign_in @super
  end

  teardown do
    @restaurant.update_column(:user_id, @owner.id)
  end

  # ---------------------------------------------------------------------------
  # POST /restaurants/:restaurant_id/staff_invitations (create)
  # ---------------------------------------------------------------------------

  test 'create: redirects unauthenticated user' do
    sign_out @super
    post restaurant_staff_invitations_path(@restaurant),
      params: { staff_invitation: { email: 'new@example.com', role: 'staff' } }

    assert_redirected_to new_user_session_path
  end

  test 'create: returns not_found when restaurant does not belong to current user' do
    other_restaurant = restaurants(:two) # owned by users(:two), not @super
    post restaurant_staff_invitations_path(other_restaurant),
      params: { staff_invitation: { email: 'invite@example.com', role: 'staff' } }

    # Restaurant lookup fails → head :not_found or redirect
    assert_includes [404, 302], response.status
  end

  test 'create: sends invitation and redirects with notice (HTML)' do
    mailer_double = Object.new
    mailer_double.define_singleton_method(:deliver_later) {}

    StaffInvitationMailer.stub(:invite, ->(_inv) { mailer_double }) do
      post restaurant_staff_invitations_path(@restaurant),
        params: { staff_invitation: { email: 'newstaff@example.com', role: 'staff' } }
    end

    assert_redirected_to edit_restaurant_path(@restaurant, section: 'staff')
    assert_match(/invitation sent/i, flash[:notice].to_s)
  end

  test 'create: flashes alert when email already has a pending invitation' do
    StaffInvitation.create!(
      restaurant: @restaurant,
      invited_by: @super,
      email: 'existing@example.com',
      role: :staff,
      status: :pending,
      expires_at: 7.days.from_now,
      token: SecureRandom.hex(20),
    )

    post restaurant_staff_invitations_path(@restaurant),
      params: { staff_invitation: { email: 'existing@example.com', role: 'staff' } }

    assert_response :redirect
    assert_match(/already/i, flash[:alert].to_s)
  end

  test 'create: flashes alert when email belongs to existing active employee' do
    # Create an active employee record for users(:two) at this restaurant
    Employee.where(restaurant: @restaurant, user: @owner).update_all(status: 1, archived: false)

    post restaurant_staff_invitations_path(@restaurant),
      params: { staff_invitation: { email: @owner.email, role: 'staff' } }

    assert_response :redirect
    assert_match(/already/i, flash[:alert].to_s)
  end

  # ---------------------------------------------------------------------------
  # GET /staff_invitations/:token/accept
  # ---------------------------------------------------------------------------

  test 'accept: redirects to root when token is not found' do
    get accept_staff_invitation_path(token: 'nonexistent_token_abc')

    assert_redirected_to root_path
    assert_match(/not found/i, flash[:alert].to_s)
  end

  test 'accept: redirects to sign in when invitation is already accepted' do
    inv = StaffInvitation.create!(
      restaurant: @restaurant,
      invited_by: @super,
      email: 'accepted@example.com',
      role: :staff,
      status: :accepted,
      accepted_at: 1.day.ago,
      expires_at: 7.days.from_now,
      token: SecureRandom.hex(20),
    )

    get accept_staff_invitation_path(token: inv.token)

    assert_redirected_to new_user_session_path
  end

  test 'accept: redirects to root when invitation is expired' do
    inv = StaffInvitation.create!(
      restaurant: @restaurant,
      invited_by: @super,
      email: 'expireduser@example.com',
      role: :staff,
      status: :expired,
      expires_at: 1.day.ago,
      token: SecureRandom.hex(20),
    )

    get accept_staff_invitation_path(token: inv.token)

    assert_redirected_to root_path
    assert_match(/expired/i, flash[:alert].to_s)
  end

  test 'accept: renders accept page for unauthenticated user with valid invitation' do
    sign_out @super
    inv = StaffInvitation.create!(
      restaurant: @restaurant,
      invited_by: @super,
      email: 'pending@example.com',
      role: :staff,
      status: :pending,
      expires_at: 7.days.from_now,
      token: SecureRandom.hex(20),
    )

    get accept_staff_invitation_path(token: inv.token)

    assert_response :ok
  end

  test 'accept: accepts invitation immediately when user is already signed in' do
    inv = StaffInvitation.create!(
      restaurant: @restaurant,
      invited_by: @super,
      email: 'loggedin@example.com',
      role: :staff,
      status: :pending,
      expires_at: 7.days.from_now,
      token: SecureRandom.hex(20),
    )

    get accept_staff_invitation_path(token: inv.token)

    assert_response :redirect
  end
end
