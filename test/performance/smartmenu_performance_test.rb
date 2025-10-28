# frozen_string_literal: true

require 'test_helper'

class SmartmenuPerformanceTest < ActiveSupport::TestCase
  # Test that SmartMenu show action doesn't have N+1 queries
  test 'smartmenu show action has no N+1 queries' do
    # Skip if no test data available
    smartmenu = Smartmenu.includes(menu: :restaurant).first
    skip 'No smartmenu test data available' unless smartmenu

    menu = smartmenu.menu
    skip 'Smartmenu has no menu' unless menu

    # Simulate what the controller does
    queries_count = count_queries do
      loaded_menu = Menu.includes(
        :restaurant,
        :menulocales,
        :menuavailabilities,
        menusections: [
          :menusectionlocales,
          { menuitems: %i[
            menuitemlocales
            allergyns
            ingredients
            sizes
            menuitem_allergyn_mappings
            menuitem_ingredient_mappings
          ] },
        ],
      ).find(menu.id)

      # Access all associations to trigger queries
      loaded_menu.restaurant.name
      loaded_menu.menulocales.to_a
      loaded_menu.menuavailabilities.to_a

      loaded_menu.menusections.each do |section|
        section.menusectionlocales.to_a
        section.menuitems.each do |item|
          item.menuitemlocales.to_a
          item.allergyns.to_a
          item.ingredients.to_a
          item.sizes.to_a
          item.menuitem_allergyn_mappings.to_a
          item.menuitem_ingredient_mappings.to_a
        end
      end
    end

    # With proper eager loading, we should have minimal queries
    # Allow some queries for the initial load, but not N+1
    assert_operator queries_count, :<, 20,
                    "Expected fewer than 20 queries with eager loading, got #{queries_count}"
  end

  test 'smartmenu show loads efficiently' do
    smartmenu = Smartmenu.includes(menu: :restaurant).first
    skip 'No smartmenu test data available' unless smartmenu

    menu = smartmenu.menu
    skip 'Smartmenu has no menu' unless menu

    # Measure load time
    start_time = Time.zone.now

    loaded_menu = Menu.includes(
      :restaurant,
      :menulocales,
      :menuavailabilities,
      menusections: [
        :menusectionlocales,
        { menuitems: %i[
          menuitemlocales
          allergyns
          ingredients
          sizes
          menuitem_allergyn_mappings
          menuitem_ingredient_mappings
        ] },
      ],
    ).find(menu.id)

    load_time = (Time.zone.now - start_time) * 1000 # Convert to ms

    # Should load in under 500ms even with all associations
    assert_operator load_time, :<, 500,
                    "Menu load took #{load_time.round(2)}ms, expected < 500ms"

    # Verify all associations are loaded
    assert loaded_menu.association(:restaurant).loaded?
    assert loaded_menu.association(:menusections).loaded?

    if loaded_menu.menusections.any?
      first_section = loaded_menu.menusections.first
      assert first_section.association(:menuitems).loaded?
    end
  end

  private

  def count_queries
    queries = []

    subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*args|
      event = ActiveSupport::Notifications::Event.new(*args)
      # Ignore schema queries and CACHE hits
      unless %w[SCHEMA CACHE].include?(event.payload[:name])
        queries << event.payload[:sql]
      end
    end

    yield

    ActiveSupport::Notifications.unsubscribe(subscriber)
    queries.size
  end
end
