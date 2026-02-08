# frozen_string_literal: true

# Testable module provides helper methods for adding test automation attributes to views.
#
# These data-testid attributes make elements easily findable in Selenium/Capybara tests
# without relying on fragile CSS classes or text content.
#
# Usage in views:
#   <button <%= test_id('submit-btn') %>>Submit</button>
#   <%= f.text_field :email, **test_id('email-input') %>
#
# Usage in tests:
#   find('[data-testid="submit-btn"]').click
#   fill_in find('[data-testid="email-input"]')[:id], with: 'test@example.com'
#
# NOTE: Test IDs only appear in test and development environments.
# Production HTML stays clean.
#
module Testable
  # Add a data-testid attribute for test automation
  #
  # @param identifier [String] Unique identifier for the element
  # @return [Hash] Empty hash in production, or { 'data-testid': identifier }
  #
  # @example Basic usage
  #   <button <%= test_id('submit-btn') %>>Submit</button>
  #   # => <button data-testid="submit-btn">Submit</button>
  #
  # @example With form helpers
  #   <%= f.text_field :name, **test_id('name-input') %>
  #   # => <input type="text" data-testid="name-input" name="user[name]">
  #
  def test_id(identifier)
    return {} unless testable_environment?

    { 'data-testid': identifier }
  end

  # Add test ID specifically for form input fields
  # Convention: {form_name}-{field_name}-input
  #
  # @param form_name [String] Name of the form (e.g., 'login', 'user', 'import')
  # @param field_name [String] Name of the field (e.g., 'email', 'password', 'name')
  # @return [Hash] Test ID hash
  #
  # @example
  #   <%= f.email_field :email, **test_field('login', 'email') %>
  #   # => <input data-testid="login-email-input" type="email">
  #
  def test_field(form_name, field_name)
    test_id("#{form_name}-#{field_name}-input")
  end

  # Add test ID specifically for buttons
  # Convention: {action}-btn
  #
  # @param action [String] Action the button performs (e.g., 'submit', 'delete', 'cancel')
  # @return [Hash] Test ID hash
  #
  # @example
  #   <button <%= test_button('submit') %>>Submit</button>
  #   # => <button data-testid="submit-btn">Submit</button>
  #
  def test_button(action)
    test_id("#{action}-btn")
  end

  # Add test ID specifically for links
  # Convention: {action}-link
  #
  # @param action [String] Action the link performs (e.g., 'edit', 'view', 'delete')
  # @return [Hash] Test ID hash
  #
  # @example
  #   <%= link_to 'Edit', edit_user_path, **test_link('edit-user') %>
  #   # => <a href="/users/1/edit" data-testid="edit-user-link">Edit</a>
  #
  def test_link(action)
    test_id("#{action}-link")
  end

  # Add test ID for list items or repeated elements with an ID
  # Convention: {base_name}-{record_id}
  #
  # @param base_name [String] Base name for the item type (e.g., 'user', 'menu', 'import')
  # @param record_id [Integer, String] ID of the record
  # @return [Hash] Test ID hash
  #
  # @example
  #   <% @users.each do |user| %>
  #     <div <%= test_item('user', user.id) %>>
  #       <%= user.name %>
  #     </div>
  #   <% end %>
  #   # => <div data-testid="user-42">John</div>
  #
  def test_item(base_name, record_id)
    test_id("#{base_name}-#{record_id}")
  end

  # Add test ID for sections/regions of the page
  # Convention: {name}-section
  #
  # @param name [String] Name of the section (e.g., 'header', 'sidebar', 'footer')
  # @return [Hash] Test ID hash
  #
  # @example
  #   <nav <%= test_section('main-nav') %>>
  #     <!-- navigation links -->
  #   </nav>
  #   # => <nav data-testid="main-nav-section">
  #
  def test_section(name)
    test_id("#{name}-section")
  end

  # Add test ID for messages/alerts
  # Convention: {type}-message
  #
  # @param type [String] Type of message (e.g., 'success', 'error', 'warning', 'info')
  # @return [Hash] Test ID hash
  #
  # @example
  #   <div class="alert alert-success" <%= test_message('success') %>>
  #     Operation completed!
  #   </div>
  #   # => <div class="alert alert-success" data-testid="success-message">
  #
  def test_message(type)
    test_id("#{type}-message")
  end

  # Combine multiple test attributes
  # Useful when you want both a test ID and other data attributes
  #
  # @param identifier [String] Test ID identifier
  # @param attrs [Hash] Other attributes to merge
  # @return [Hash] Merged attributes
  #
  # @example
  #   <%= link_to 'View', user_path, **test_attrs('view-user', turbo_frame: '_top') %>
  #   # => <a data-testid="view-user" data-turbo-frame="_top">View</a>
  #
  def test_attrs(identifier, **attrs)
    return attrs unless testable_environment?

    { 'data-testid': identifier }.merge(attrs)
  end

  private

  # Check if we should add test attributes
  # Only add in test and development environments to keep production HTML clean
  #
  # @return [Boolean]
  def testable_environment?
    Rails.env.local?
  end
end
