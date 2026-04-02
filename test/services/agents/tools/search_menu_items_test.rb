# frozen_string_literal: true

require 'test_helper'

class Agents::Tools::SearchMenuItemsTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
  end

  test 'tool_name is search_menu_items' do
    assert_equal 'search_menu_items', Agents::Tools::SearchMenuItems.tool_name
  end

  test 'description is present' do
    assert Agents::Tools::SearchMenuItems.description.present?
  end

  test 'input_schema requires restaurant_id' do
    schema = Agents::Tools::SearchMenuItems.input_schema
    assert_equal 'object', schema[:type]
    assert_includes schema[:required], 'restaurant_id'
  end

  test 'input_schema includes exclude_allergyn_ids property' do
    props = Agents::Tools::SearchMenuItems.input_schema[:properties]
    assert props.key?(:exclude_allergyn_ids), 'Expected exclude_allergyn_ids in properties'
    assert_equal 'array', props[:exclude_allergyn_ids][:type]
  end

  test 'call returns items for restaurant' do
    result = Agents::Tools::SearchMenuItems.call('restaurant_id' => @restaurant.id)
    assert result.key?(:items)
    assert result.key?(:total)
    assert_instance_of Array, result[:items]
  end

  test 'call excludes items with specified allergen IDs' do
    # Create a menuitem and map it to an allergyn
    allergyn = allergyns(:one)
    item = Menuitem.find_by(menusection: menusections(:one))
    return skip('No menuitems fixture available') unless item

    # Map the item to the allergyn
    MenuitemAllergynMapping.create!(menuitem: item, allergyn: allergyn)

    # Without exclusion: item should appear
    result_without = Agents::Tools::SearchMenuItems.call('restaurant_id' => @restaurant.id)
    ids_without = result_without[:items].map { |i| i[:id] }
    assert_includes ids_without, item.id

    # With exclusion: item should not appear
    result_with = Agents::Tools::SearchMenuItems.call(
      'restaurant_id'        => @restaurant.id,
      'exclude_allergyn_ids' => [allergyn.id],
    )
    ids_with = result_with[:items].map { |i| i[:id] }
    assert_not_includes ids_with, item.id
  ensure
    MenuitemAllergynMapping.where(menuitem: item, allergyn: allergyn).destroy_all if item && allergyn
  end

  test 'call accepts symbol keys for exclude_allergyn_ids' do
    result = Agents::Tools::SearchMenuItems.call(
      restaurant_id: @restaurant.id,
      exclude_allergyn_ids: [],
    )
    assert result.key?(:items)
  end

  test 'call ignores zero or invalid allergen IDs' do
    result = Agents::Tools::SearchMenuItems.call(
      'restaurant_id'        => @restaurant.id,
      'exclude_allergyn_ids' => [0, -1, nil],
    )
    assert result.key?(:items)
  end

  test 'call respects max_price filter' do
    result = Agents::Tools::SearchMenuItems.call(
      'restaurant_id' => @restaurant.id,
      'max_price'     => 5.0,
    )
    result[:items].each do |item|
      assert item[:price] <= 5.0, "Expected price <= 5.0 but got #{item[:price]}"
    end
  end

  test 'call respects limit' do
    result = Agents::Tools::SearchMenuItems.call(
      'restaurant_id' => @restaurant.id,
      'limit'         => 1,
    )
    assert result[:items].size <= 1
  end
end
