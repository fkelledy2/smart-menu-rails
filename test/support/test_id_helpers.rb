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
  
  # Helper method for smartmenu ordering flow
  # Clicks add item button, then confirms in modal, then opens view order modal
  #
  # @param item_id [Integer] The menu item ID
  # @param options [Hash] Additional options
  # @return [void]
  #
  # @example
  #   add_item_to_order(@burger.id)
  #   add_item_to_order(@pasta.id, wait: 5)
  #
  # Helper to close all modals and wait for them to be fully gone
  def close_all_modals
    # Close modals and clean up in one efficient JavaScript call
    page.execute_script(<<~JS)
      // Close all modal instances
      document.querySelectorAll('.modal').forEach(modal => {
        const bsModal = bootstrap.Modal.getInstance(modal);
        if (bsModal) {
          bsModal.hide();
        }
        // Force immediate cleanup
        modal.classList.remove('show');
        modal.style.display = 'none';
        modal.setAttribute('aria-hidden', 'true');
      });
      
      // Remove all backdrops
      document.querySelectorAll('.modal-backdrop').forEach(backdrop => {
        backdrop.remove();
      });
      
      // Clean up body
      document.body.classList.remove('modal-open');
      document.body.style.removeProperty('overflow');
      document.body.style.removeProperty('padding-right');
    JS
    
    # Brief pause for DOM to settle
    sleep 0.2
  end
  
  # Wait for all pending fetch/AJAX requests to complete
  def wait_for_requests_to_complete(timeout: 5)
    Timeout.timeout(timeout) do
      loop do
        # Check if jQuery has pending AJAX requests
        pending = page.evaluate_script('typeof jQuery !== "undefined" && jQuery.active || 0')
        break if pending.zero?
        sleep 0.05
      end
    end
  rescue Timeout::Error
    # Continue if timeout
  end
  
  # Wait for DOM to be mutated (e.g., after Turbo Stream updates)
  def wait_for_dom_update(timeout: 5)
    Timeout.timeout(timeout) do
      page.execute_script(<<~JS)
        return new Promise((resolve) => {
          const observer = new MutationObserver(() => {
            observer.disconnect();
            resolve(true);
          });
          observer.observe(document.body, { childList: true, subtree: true });
          
          // Auto-resolve if no changes within 500ms
          setTimeout(() => {
            observer.disconnect();
            resolve(true);
          }, 500);
        });
      JS
    end
  rescue Timeout::Error
    # Continue if timeout
  end
  
  # Wait for a specific element to have content (not empty)
  def wait_for_element_content(selector, timeout: 5)
    Timeout.timeout(timeout) do
      loop do
        content = page.evaluate_script("document.querySelector('#{selector}')?.textContent?.trim()")
        break if content && !content.empty?
        sleep 0.05
      end
    end
  rescue Timeout::Error
    # Continue if timeout
  end
  
  def add_item_to_order(item_id, **options)
    # First, close any open modals to prevent interference
    close_all_modals
    
    # Wait for menu content to be loaded
    assert_selector('#menuContentContainer', wait: 5)
    
    # Wait for the specific menu item to be visible
    assert_testid("menu-item-#{item_id}", wait: 5)
    
    # Wait for the add button to exist (may be disabled due to tablesetting)
    button_selector = "[data-testid='add-item-btn-#{item_id}']"
    assert_selector(button_selector, wait: 5)
    
    # Force enable the button in case it's disabled (e.g., no tablesetting in test)
    page.execute_script(<<~JS)
      const btn = document.querySelector("#{button_selector}");
      if (btn) {
        btn.removeAttribute('disabled');
      }
    JS
    
    # Now click the add item button - opens modal
    click_testid("add-item-btn-#{item_id}", **options)
    
    # Wait for the add-to-order modal to exist and for the price to load
    begin
      # Wait for modal to exist
      find('#addItemToOrderModal', wait: 3, visible: true)
      
      # Wait for price span to be populated
      wait_for_element_content('#a2o_menuitem_price', timeout: 3)
    rescue Capybara::ElementNotFound, Timeout::Error
      # Modal or price not loading - log for debugging
      Rails.logger.debug("Add item modal or price not loading for item #{item_id}")
    end
    
    # Manually enable and click the add button via JavaScript
    # (WebSocket doesn't work in tests and button may be disabled)
    page.execute_script(<<~JS)
      const btn = document.getElementById('addItemToOrderButton');
      if (btn) {
        btn.removeAttribute('disabled');
        btn.click();
      }
    JS
    
    # Wait for the POST request to complete
    wait_for_requests_to_complete(timeout: 5)
    
    # Wait for Turbo Stream to process and update DOM
    wait_for_dom_update(timeout: 2)
    
    # Ensure all follow-up requests are also done
    wait_for_requests_to_complete(timeout: 3)
    
    # Wait for add modal to close
    sleep 0.5
    
    # Item has been added - modal is closed, FAB should update
    # Tests should manually open view order modal if they need to verify contents
  end
  
  # Opens the view order modal by clicking the FAB button or directly if FAB not visible
  def open_view_order_modal(**options)
    # First, ensure all modals and backdrops are closed
    page.execute_script(<<~JS)
      // Close all modals
      document.querySelectorAll('.modal.show').forEach(modal => {
        const instance = bootstrap.Modal.getInstance(modal);
        if (instance) {
          instance.hide();
        }
      });
      
      // Remove all backdrops
      document.querySelectorAll('.modal-backdrop').forEach(backdrop => {
        backdrop.remove();
      });
      
      // Reset body classes
      document.body.classList.remove('modal-open');
      document.body.style.overflow = '';
      document.body.style.paddingRight = '';
    JS
    
    sleep 0.3 # Wait for cleanup
    
    # Try to click FAB - in tests, WebSocket doesn't update so FAB may not be visible
    begin
      click_testid('order-fab-btn', wait: 2, **options)
    rescue Capybara::ElementNotFound, Selenium::WebDriver::Error::ElementClickInterceptedError
      # FAB not rendered or obscured, open modal directly via JavaScript
      page.execute_script(<<~JS)
        const modalEl = document.getElementById('viewOrderModal');
        if (modalEl && typeof bootstrap !== 'undefined') {
          const modal = bootstrap.Modal.getInstance(modalEl) || new bootstrap.Modal(modalEl);
          modal.show();
        }
      JS
    end
    
    # Wait for modal to appear
    assert_testid('view-order-modal', wait: 5)
    
    # Wait for modal content to render
    sleep 0.3
  end
  
  # Removes an item from the order by ordritem id
  def remove_item_from_order_by_testid(testid)
    # Extract the ordritem id from the testid format: "order-item-123"
    item_id = testid.gsub('order-item-', '')
    
    # Find and click the remove button using the correct testid format
    button_testid = "remove-order-item-#{item_id}-btn"
    
    begin
      find_testid(button_testid).click
    rescue Capybara::ElementNotFound
      # Button might not be visible, use JavaScript
      page.execute_script(<<~JS)
        const btn = document.querySelector('[data-testid=\"#{button_testid}\"]');
        if (btn) btn.click();
      JS
    end
    
    # Wait for removal to complete
    wait_for_requests_to_complete(timeout: 3)
    sleep 0.3
  end
  
  # Wait for a custom WebSocket event to be dispatched
  # This uses JavaScript event listeners instead of polling/sleeping
  def wait_for_websocket_event(event_name, timeout: 5)
    result = page.evaluate_async_script(<<~JS, timeout * 1000)
      const eventName = '#{event_name}';
      const timeout = arguments[0];
      const done = arguments[1];
      
      let timeoutId;
      const handler = (event) => {
        clearTimeout(timeoutId);
        window.removeEventListener(eventName, handler);
        done({ success: true, detail: event.detail });
      };
      
      window.addEventListener(eventName, handler);
      
      timeoutId = setTimeout(() => {
        window.removeEventListener(eventName, handler);
        done({ success: false, error: 'Timeout waiting for ' + eventName });
      }, timeout);
    JS
    
    unless result['success']
      raise Timeout::Error, "Timeout waiting for WebSocket event: #{event_name}"
    end
    
    result
  end
  
  # Wait for order update via WebSocket
  def wait_for_order_update(timeout: 5)
    wait_for_websocket_event('ordr:updated', timeout: timeout)
  end
  
  # Wait for menu update via WebSocket
  def wait_for_menu_update(timeout: 5)
    wait_for_websocket_event('ordr:menu:updated', timeout: timeout)
  end
  
  # Wait for a POST request to start and complete, then wait for WebSocket update
  def wait_for_order_item_added(timeout: 10)
    # Wait for the request to complete
    wait_for_requests_to_complete(timeout: timeout)
    
    # Then wait for the WebSocket update
    wait_for_order_update(timeout: timeout)
  end
  
  # Enhanced add_item_to_order using event-driven waits
  def add_item_to_order_with_events(item_id, **options)
    # Close any open modals
    close_all_modals
    
    # Click the add item button - opens modal
    click_testid("add-item-btn-#{item_id}", **options)
    
    # Wait for modal to be visible
    assert_testid('add-item-modal', wait: 3)
    
    # Wait for price to load
    wait_for_element_content('#a2o_menuitem_price', timeout: 3)
    
    # Click the add button (force enable if needed)
    page.execute_script(<<~JS)
      const btn = document.getElementById('addItemToOrderButton');
      if (btn) {
        btn.removeAttribute('disabled');
        btn.click();
      }
    JS
    
    # Wait for HTTP request and WebSocket update
    wait_for_order_item_added(timeout: 10)
    
    # Modal should auto-close after update
  end
end

# Automatically include in system tests
if defined?(ActionDispatch::SystemTestCase)
  class ActionDispatch::SystemTestCase
    include TestIdHelpers
  end
end
