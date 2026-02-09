require 'application_system_test_case'

class AdminImpersonationFlowTest < ApplicationSystemTestCase
  test 'super admin can impersonate a user, is blocked from high-risk actions, and can stop with audit' do
    super_admin = User.find_by(email: 'admin@mellow.menu')
    super_admin ||= User.create!(
      email: 'admin@mellow.menu',
      password: 'password123',
      password_confirmation: 'password123',
      first_name: 'Admin',
      last_name: 'User',
    )
    super_admin.update!(admin: true, super_admin: true, password: 'password123', password_confirmation: 'password123')

    target = User.find_by(email: 'target@example.com')
    target ||= User.create!(
      email: 'target@example.com',
      password: 'password123',
      password_confirmation: 'password123',
      first_name: 'Target',
      last_name: 'User',
    )

    visit new_user_session_path
    fill_testid('login-email-input', super_admin.email)
    fill_testid('login-password-input', 'password123')
    click_testid('login-submit-btn')

    assert_current_path restaurants_path, ignore_query: true

    visit new_admin_impersonation_path
    fill_testid('admin-impersonation-query', target.email)
    click_testid('admin-impersonation-submit')

    assert_selector('.alert.alert-warning', wait: 5)
    assert_selector('.alert.alert-warning', text: target.email)

    visit edit_user_registration_path
    assert_not_equal edit_user_registration_path, URI.parse(current_url).path
    assert_text 'This action is not allowed while impersonating.'

    visit root_path
    click_testid('stop-impersonation-btn')

    assert_selector('body')
    assert_no_selector('.alert.alert-warning', text: target.email)

    audit = ImpersonationAudit.order(:id).last
    assert_equal super_admin.id, audit.admin_user_id
    assert_equal target.id, audit.impersonated_user_id
    assert_equal 'manual_stop', audit.ended_reason
    assert audit.ended_at.present?
  end
end
