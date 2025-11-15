# frozen_string_literal: true

# TestIdHelpers provides convenient methods for finding elements by data-testid
# in Capybara/Selenium tests.
#
# These helpers match the Testable module used in views, making tests more readable
# and less fragile than using CSS classes or text content.
#
# Usage:
#   find_testid('submit-btn').click
#   fill_testid('email-input', 'user@example.com')
#   click_testid('delete-btn')
#   assert_testid('success-message')
#
module TestIdHelpers
  # Find an element by its data-testid attribute
  #
  # @param testid [String] The test ID to find
  # @param options [Hash] Additional Capybara options (wait, visible, etc.)
  # @return [Capybara::Node::Element] The found element
  #
  # @example
  #   button = find_testid('submit-btn')
  #   button.click
  #
  # @example With options
  #   find_testid('loading-spinner', visible: false)
  #   find_testid('error-message', wait: 10)
  #
  def find_testid(testid, **options)
    find("[data-testid='#{testid}']", **options)
  end

  # Find all elements matching a data-testid pattern
  #
  # @param testid_pattern [String] Pattern to match (can use * for wildcards in selector)
  # @return [Array<Capybara::Node::Element>] Array of matching elements
  #
  # @example Find all user rows
  #   all_testid('user-').each do |user_row|
  #     puts user_row.text
  #   end
  #
  def all_testid(testid_pattern)
    all("[data-testid^='#{testid_pattern}']")
  end

  # Click an element by its data-testid
  #
  # @param testid [String] The test ID to click
  # @param options [Hash] Additional Capybara options
  # @return [void]
  #
  # @example
  #   click_testid('submit-btn')
  #   click_testid('confirm-btn', wait: 5)
  #
  def click_testid(testid, **options)
    find_testid(testid, **options).click
  end

  # Fill in a form field by its data-testid
  #
  # @param testid [String] The test ID of the input field
  # @param value [String] The value to fill in
  # @param options [Hash] Additional options
  # @return [void]
  #
  # @example
  #   fill_testid('email-input', 'user@example.com')
  #   fill_testid('password-input', 'secret123')
  #
  def fill_testid(testid, value, **options)
    element = find_testid(testid, **options)
    # Get the actual input ID (might be nested)
    input_id = element[:id]
    fill_in input_id, with: value
  end

  # Attach a file to a file input by its data-testid
  #
  # @param testid [String] The test ID of the file input
  # @param file_path [String] Path to the file to attach
  # @param options [Hash] Additional options
  # @return [void]
  #
  # @example
  #   attach_testid('avatar-input', Rails.root.join('test/fixtures/files/avatar.jpg'))
  #   attach_testid('pdf-input', file_fixture('menu.pdf'))
  #
  def attach_testid(testid, file_path, **options)
    element = find_testid(testid, **options)
    # File inputs might be hidden, need to find them differently
    input_id = element[:id] || element.find('input[type="file"]', visible: :all)[:id]
    attach_file input_id, file_path
  end

  # Check if an element with the given test ID exists
  #
  # @param testid [String] The test ID to check for
  # @param options [Hash] Additional Capybara options
  # @return [Boolean] true if element exists, false otherwise
  #
  # @example
  #   if has_testid?('error-message')
  #     # Handle error
  #   end
  #
  def has_testid?(testid, **options)
    has_selector?("[data-testid='#{testid}']", **options)
  end

  # Check if an element with the given test ID does NOT exist
  #
  # @param testid [String] The test ID to check for
  # @param options [Hash] Additional Capybara options
  # @return [Boolean] true if element does not exist, false otherwise
  #
  # @example
  #   assert has_no_testid?('loading-spinner')
  #
  def has_no_testid?(testid, **options)
    has_no_selector?("[data-testid='#{testid}']", **options)
  end

  # Wait for an element to appear by its test ID
  #
  # @param testid [String] The test ID to wait for
  # @param timeout [Integer] Maximum time to wait in seconds
  # @return [Capybara::Node::Element] The found element
  #
  # @example
  #   click_testid('submit-btn')
  #   wait_for_testid('success-message', timeout: 10)
  #
  def wait_for_testid(testid, timeout: Capybara.default_max_wait_time)
    find_testid(testid, wait: timeout)
  end

  # Wait for an element to disappear by its test ID
  #
  # @param testid [String] The test ID to wait for disappearance
  # @param timeout [Integer] Maximum time to wait in seconds
  # @return [Boolean] true if element disappeared
  #
  # @example
  #   click_testid('delete-btn')
  #   wait_for_no_testid('user-42')
  #
  def wait_for_no_testid(testid, timeout: Capybara.default_max_wait_time)
    has_no_selector?("[data-testid='#{testid}']", wait: timeout)
  end

  # Scope actions within an element with a specific test ID
  #
  # @param testid [String] The test ID of the container
  # @param options [Hash] Additional Capybara options
  # @yield Block of code to execute within the scoped element
  # @return [void]
  #
  # @example
  #   within_testid('login-form') do
  #     fill_testid('email-input', 'user@example.com')
  #     fill_testid('password-input', 'password')
  #     click_testid('submit-btn')
  #   end
  #
  def within_testid(testid, **options, &block)
    within("[data-testid='#{testid}']", **options, &block)
  end

  # Get the text content of an element by its test ID
  #
  # @param testid [String] The test ID
  # @param options [Hash] Additional Capybara options
  # @return [String] The text content
  #
  # @example
  #   username = text_from_testid('username-display')
  #   assert_equal 'John Doe', username
  #
  def text_from_testid(testid, **options)
    find_testid(testid, **options).text
  end

  # Get the value of an input element by its test ID
  #
  # @param testid [String] The test ID
  # @param options [Hash] Additional Capybara options
  # @return [String] The input value
  #
  # @example
  #   email = value_from_testid('email-input')
  #   assert_includes email, '@example.com'
  #
  def value_from_testid(testid, **options)
    find_testid(testid, **options).value
  end

  # Assert that an element with the test ID exists
  #
  # @param testid [String] The test ID
  # @param options [Hash] Additional assertion options
  # @return [void]
  #
  # @example
  #   assert_testid('success-message')
  #   assert_testid('user-profile', text: 'John Doe')
  #
  def assert_testid(testid, **options)
    assert_selector "[data-testid='#{testid}']", **options
  end

  # Assert that an element with the test ID does NOT exist
  #
  # @param testid [String] The test ID
  # @param options [Hash] Additional assertion options
  # @return [void]
  #
  # @example
  #   click_testid('delete-btn')
  #   assert_no_testid('user-42')
  #
  def assert_no_testid(testid, **options)
    assert_no_selector "[data-testid='#{testid}']", **options
  end

  # Select an option from a select dropdown by test ID
  #
  # @param testid [String] The test ID of the select element
  # @param value [String] The option to select
  # @param options [Hash] Additional options
  # @return [void]
  #
  # @example
  #   select_testid('country-select', 'United States')
  #   select_testid('role-select', 'Admin')
  #
  def select_testid(testid, value, **options)
    element = find_testid(testid, **options)
    select value, from: element[:id]
  end

  # Check a checkbox by test ID
  #
  # @param testid [String] The test ID of the checkbox
  # @param options [Hash] Additional options
  # @return [void]
  #
  # @example
  #   check_testid('terms-checkbox')
  #   check_testid('subscribe-checkbox')
  #
  def check_testid(testid, **options)
    element = find_testid(testid, **options)
    check element[:id]
  end

  # Uncheck a checkbox by test ID
  #
  # @param testid [String] The test ID of the checkbox
  # @param options [Hash] Additional options
  # @return [void]
  #
  # @example
  #   uncheck_testid('newsletter-checkbox')
  #
  def uncheck_testid(testid, **options)
    element = find_testid(testid, **options)
    uncheck element[:id]
  end
end

# Automatically include in system tests
if defined?(ActionDispatch::SystemTestCase)
  class ActionDispatch::SystemTestCase
    include TestIdHelpers
  end
end
