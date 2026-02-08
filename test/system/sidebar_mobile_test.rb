require 'application_system_test_case'

class SidebarMobileTest < ApplicationSystemTestCase
  setup do
    @restaurant = restaurants(:one)
    @user = users(:one)
    Warden.test_mode!
    login_as(@user, scope: :user)
  end

  teardown do
    Warden.test_reset!
  end

  test 'sidebar toggle works on mobile' do
    # Resize to mobile viewport
    page.driver.browser.manage.window.resize_to(375, 667) # iPhone SE size

    visit edit_restaurant_path(@restaurant, section: 'details')

    # Wait for page to load
    assert_selector('[data-controller="sidebar"]')

    # Verify sidebar is hidden initially on mobile
    assert_selector('.sidebar-2025', visible: false)

    # Find and click the toggle button
    toggle_button = find('.sidebar-toggle-btn', visible: true)
    toggle_button.click

    # Wait for sidebar to slide in
    sleep 0.5

    # Verify sidebar is now visible
    assert_selector('.sidebar-2025.open', visible: true)

    # Verify overlay is active
    assert_selector('.sidebar-overlay.active', visible: true)

    # Verify body scroll is prevented
    assert_equal 'hidden', page.evaluate_script('document.body.style.overflow')

    # Close via sidebar close button (more reliable than overlay click in Selenium)
    within('.sidebar-header') do
      find('button[aria-label="Close menu"]').click
    end

    # Wait for sidebar to slide out
    sleep 0.5

    # Verify sidebar is hidden again
    assert_no_selector('.sidebar-2025.open')

    # Verify overlay is inactive
    assert_no_selector('.sidebar-overlay.active')

    # Verify body scroll is restored
    assert_equal '', page.evaluate_script('document.body.style.overflow')
  end

  test 'sidebar close button works' do
    # Resize to mobile viewport
    page.driver.browser.manage.window.resize_to(375, 667)

    visit edit_restaurant_path(@restaurant, section: 'details')

    # Open sidebar
    find('.sidebar-toggle-btn').click
    sleep 0.5

    # Verify sidebar is open
    assert_selector('.sidebar-2025.open', visible: true)

    # Click close button in sidebar header
    within('.sidebar-header') do
      find('button[aria-label="Close menu"]').click
    end

    sleep 0.5

    # Verify sidebar is closed
    assert_no_selector('.sidebar-2025.open')
  end

  test 'sidebar navigation links work' do
    # Resize to mobile viewport
    page.driver.browser.manage.window.resize_to(375, 667)

    visit edit_restaurant_path(@restaurant, section: 'details')

    # Open sidebar
    find('.sidebar-toggle-btn').click
    sleep 0.5

    # Click details link (address is part of details section in 2025 sidebar)
    within("[data-testid='restaurant-sidebar']") do
      find("[data-testid='sidebar-details-link']").click
    end

    # Wait for Turbo Frame to load
    sleep 1

    # Verify URL is still in details section (address is rendered within details)
    assert_current_path edit_restaurant_path(@restaurant, section: 'details')

    # On mobile, sidebar should close after clicking link
    # (based on handleLinkClick method)
    sleep 0.5
    assert_no_selector('.sidebar-2025.open')
  end

  test 'sidebar debounce prevents rapid toggles' do
    # Resize to mobile viewport
    page.driver.browser.manage.window.resize_to(375, 667)

    visit edit_restaurant_path(@restaurant, section: 'details')

    # Rapidly click via JS to avoid Selenium click interception once overlay appears
    page.execute_script(<<~JS)
      const btn = document.querySelector('.sidebar-toggle-btn');
      if (btn) {
        for (let i = 0; i < 5; i++) {
          btn.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true }));
        }
      }
    JS

    # Wait for animation
    sleep 0.5

    # Sidebar should be open (not toggled multiple times)
    assert_selector('.sidebar-2025.open', visible: true)

    # Should not have closed immediately
    assert_selector('.sidebar-overlay.active', visible: true)
  end

  test 'sidebar hides on desktop resize' do
    # Start at mobile size
    page.driver.browser.manage.window.resize_to(375, 667)

    visit edit_restaurant_path(@restaurant, section: 'details')

    # Open sidebar
    find('.sidebar-toggle-btn').click
    sleep 0.5

    assert_selector('.sidebar-2025.open', visible: true)

    # Resize to desktop
    page.driver.browser.manage.window.resize_to(1024, 768)

    # Wait for resize handler
    sleep 0.5

    # Sidebar should close on desktop resize
    assert_no_selector('.sidebar-2025.open')
  end

  private

  def sign_in(user)
    visit new_user_session_path
    fill_in 'Email', with: user.email
    fill_in 'Password', with: 'password'
    if page.has_selector?("[data-testid='login-submit-btn']", wait: 2)
      find("[data-testid='login-submit-btn']").click
    else
      begin
        first(:button, 'Sign in', wait: 2)&.click
      rescue StandardError
        nil
      end
      first("input[type='submit']").click if page.has_selector?("input[type='submit']", wait: 2)
    end
  end
end
