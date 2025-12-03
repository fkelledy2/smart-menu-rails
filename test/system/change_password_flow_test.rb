# frozen_string_literal: true

require 'application_system_test_case'

class ChangePasswordFlowTest < ApplicationSystemTestCase
  test 'user can change password from account settings' do
    # Create a user
    user = User.create!(
      email: "changepw_#{Time.now.to_i}@example.com",
      password: 'oldpassword1',
      password_confirmation: 'oldpassword1',
      first_name: 'Change',
      last_name: 'Me'
    )

    # Sign in
    visit new_user_session_path
    fill_in 'user_email', with: user.email
    fill_in 'user_password', with: 'oldpassword1'
    # Use test id button for reliability
    if page.has_selector?("[data-testid='login-submit-btn']", wait: 3)
      find("[data-testid='login-submit-btn']").click
    else
      find('input[type="submit"]').click
    end
    # Ensure login worked before proceeding
    assert_no_current_path new_user_session_path

    # Go to account settings
    visit edit_user_registration_path
    # Ensure fields are present before interacting (by label for robustness)
    assert_selector(:field, 'New Password', wait: 5)
    assert_selector(:field, 'Confirm New Password', wait: 5)
    assert_selector(:field, 'Current Password', wait: 5)

    # Change password: set new password and confirm, provide current password
    fill_in 'New Password', with: 'newpassword1'
    fill_in 'Confirm New Password', with: 'newpassword1'
    fill_in 'Current Password', with: 'oldpassword1'

    # Submit form
    find('input[type="submit"]').click

    # Devise default success message
    assert_text 'Your account has been updated successfully'

    # Sign out via JS fetch to ensure new session for login verification
    page.evaluate_async_script(<<~JS, 10000)
      const done = arguments[1];
      (async () => {
        try {
          const token = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content');
          const res = await fetch('#{Rails.application.routes.url_helpers.destroy_user_session_path}', {
            method: 'DELETE',
            headers: { 'X-CSRF-Token': token, 'Accept': 'text/vnd.turbo-stream.html, text/html, application/xhtml+xml' },
            credentials: 'same-origin'
          });
          done({ ok: res.ok, status: res.status });
        } catch (e) { done({ ok: false, error: String(e) }); }
      })();
    JS

    # Verify login works with new password
    visit new_user_session_path
    fill_in 'user_email', with: user.email
    fill_in 'user_password', with: 'newpassword1'
    find('input[type="submit"]').click
    assert_current_path root_path, ignore_query: true

    # Optional: old password should fail now
    page.evaluate_async_script(<<~JS, 10000)
      const done = arguments[1];
      (async () => {
        try {
          const token = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content');
          const res = await fetch('#{Rails.application.routes.url_helpers.destroy_user_session_path}', {
            method: 'DELETE', headers: { 'X-CSRF-Token': token }, credentials: 'same-origin'
          });
          done({ ok: res.ok, status: res.status });
        } catch (e) { done({ ok: false, error: String(e) }); }
      })();
    JS

    visit new_user_session_path
    fill_in 'user_email', with: user.email
    fill_in 'user_password', with: 'oldpassword1'
    find('input[type="submit"]').click
    assert_current_path new_user_session_path

    user.destroy
  end
end
