# frozen_string_literal: true

module MenuTestHelpers
  # Create a menu and ensure all after_commit callbacks complete
  # This is necessary because Menu has an after_commit callback that creates RestaurantMenu
  def create_menu_with_callbacks(attributes = {})
    menu = Menu.create!(attributes)

    # Ensure the after_commit callback has created the RestaurantMenu record
    # In test environment, after_commit callbacks run immediately after transaction commit
    # but we need to ensure the record exists before proceeding
    if menu.restaurant_id.present?
      RestaurantMenu.find_or_create_by!(
        restaurant_id: menu.restaurant_id,
        menu_id: menu.id,
      ) do |rm|
        rm.sequence = RestaurantMenu.where(restaurant_id: menu.restaurant_id).maximum(:sequence).to_i + 1
        rm.status = :active
        rm.availability_override_enabled = false
        rm.availability_state = :available
      end
    end

    menu
  end

  # Wait for Turbo frame to finish loading by checking for specific content
  def wait_for_turbo_frame(frame_id, timeout: 5)
    using_wait_time(timeout) do
      assert_selector("turbo-frame##{frame_id}[complete]", visible: false)
    end
  rescue Capybara::ElementNotFound
    # Frame might not have complete attribute, just wait for it to be present
    assert_selector("turbo-frame##{frame_id}", wait: timeout)
  end
end
