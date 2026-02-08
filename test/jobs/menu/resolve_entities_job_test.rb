require 'test_helper'

class ResolveEntitiesJobTest < ActiveSupport::TestCase
  setup do
    @restaurant = restaurants(:one)
    @menu = menus(:one)
    @menu.update!(restaurant: @restaurant) if @menu.restaurant != @restaurant

    @menusection = menusections(:one)
    @menusection.update!(menu: @menu) if @menusection.menu != @menu

    @menuitem = Menuitem.create!(
      menusection: @menusection,
      name: 'Lagavulin 16',
      description: 'Islay single malt',
      price: 18.0,
      calories: 0,
      preptime: 0,
      sequence: 999,
      status: 'active',
      itemtype: 'spirits',
      sommelier_category: 'whiskey',
      sommelier_classification_confidence: 0.95,
      sommelier_parsed_fields: { 'name_raw' => 'Lagavulin 16', 'age_years' => 16, 'bottling_strength_abv' => 43.0 },
      sommelier_parse_confidence: 0.9,
      sommelier_needs_review: true,
    )

    @run = BeveragePipelineRun.create!(
      restaurant: @restaurant,
      menu: @menu,
      status: 'running',
      started_at: Time.current,
      current_step: 'extract_candidates',
    )
  end

  test 'creates product and link and clears needs_review when confident' do
    assert_difference('Product.count', 1) do
      assert_difference('MenuItemProductLink.count', 1) do
        Menu::ResolveEntitiesJob.new.perform(@run.id, 'test')
      end
    end

    @menuitem.reload
    assert_equal false, @menuitem.sommelier_needs_review

    link = MenuItemProductLink.where(menuitem_id: @menuitem.id).first
    assert link
    product = link.product
    assert_equal 'whiskey', product.product_type
    assert_match(/Lagavulin 16/, product.canonical_name)
    assert link.resolution_confidence.to_f >= 0.7
    assert_includes link.explanations.to_s, 'Auto-resolved'
  end
end
