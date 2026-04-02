# frozen_string_literal: true

require 'test_helper'

class Agents::Tools::ProposeBasketTest < ActiveSupport::TestCase
  def setup
    @items = Menuitem.limit(5).to_a
  end

  test 'tool_name is propose_basket' do
    assert_equal 'propose_basket', Agents::Tools::ProposeBasket.tool_name
  end

  test 'description is present' do
    assert Agents::Tools::ProposeBasket.description.present?
  end

  test 'input_schema requires item_ids' do
    schema = Agents::Tools::ProposeBasket.input_schema
    assert_includes schema[:required], 'item_ids'
  end

  test 'call returns empty basket for empty item_ids' do
    result = Agents::Tools::ProposeBasket.call('item_ids' => [])
    assert_equal [], result[:items]
    assert_equal 0, result[:total]
  end

  test 'call returns items and total' do
    return skip('No menuitems available') if @items.empty?

    item_ids = @items.map(&:id)
    result = Agents::Tools::ProposeBasket.call('item_ids' => item_ids, 'group_size' => 2)

    assert result[:items].is_a?(Array)
    assert result[:total].is_a?(Numeric)
    assert_operator result[:items].size, :>=, 1
  end

  test 'call respects budget constraint' do
    return skip('No menuitems available') if @items.empty?

    item_ids = @items.map(&:id)
    max_budget = 1.0

    result = Agents::Tools::ProposeBasket.call(
      'item_ids'   => item_ids,
      'group_size' => 2,
      'budget'     => max_budget,
    )

    assert result[:total] <= max_budget + 0.01, \
      "Expected total #{result[:total]} to be within budget #{max_budget}"
  end

  test 'call handles string keys and integer group_size' do
    return skip('No menuitems available') if @items.empty?

    result = Agents::Tools::ProposeBasket.call(
      'item_ids'   => @items.map(&:id),
      'group_size' => '4',
    )

    assert result.key?(:group_size)
    assert_equal 4, result[:group_size]
  end

  test 'call clamps group_size minimum to 1' do
    return skip('No menuitems available') if @items.empty?

    result = Agents::Tools::ProposeBasket.call(
      'item_ids'   => @items.map(&:id),
      'group_size' => 0,
    )

    assert_equal 1, result[:group_size]
  end

  test 'call does not exceed MAX_ITEMS_IN_BASKET' do
    # Generate more IDs than the cap
    items = Menuitem.all.to_a
    return skip('Not enough menuitems') if items.size < 2

    result = Agents::Tools::ProposeBasket.call(
      'item_ids'   => items.map(&:id),
      'group_size' => 100,
    )

    assert result[:items].size <= Agents::Tools::ProposeBasket::MAX_ITEMS_IN_BASKET
  end
end
