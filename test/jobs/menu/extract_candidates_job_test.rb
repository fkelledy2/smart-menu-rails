require 'test_helper'

class ExtractCandidatesJobTest < ActiveSupport::TestCase
  setup do
    @restaurant = restaurants(:one)
    @menu = menus(:one)
    @menu.update!(restaurant: @restaurant) if @menu.restaurant != @restaurant

    @menusection = menusections(:one)
    @menusection.update!(menu: @menu) if @menusection.menu != @menu

    @whiskey_item = Menuitem.create!(
      menusection: @menusection,
      name: 'Redbreast 12yo Whiskey 40% 50ml',
      description: 'Irish single pot still',
      price: 12.0,
      calories: 0,
      preptime: 0,
      sequence: 999,
      status: 'active',
      itemtype: 'spirit',
    )

    @wine_item = Menuitem.create!(
      menusection: @menusection,
      name: 'Barolo 2018 750ml',
      description: 'Nebbiolo, Piedmont',
      price: 80.0,
      calories: 0,
      preptime: 0,
      sequence: 1000,
      status: 'active',
      itemtype: 'wine',
    )

    @run = BeveragePipelineRun.create!(
      restaurant: @restaurant,
      menu: @menu,
      status: 'running',
      started_at: Time.current,
      current_step: 'start',
    )
  end

  test 'classifies and parses whiskey and wine candidates' do
    Menu::ExtractCandidatesJob.new.perform(@run.id, 'test')

    @whiskey_item.reload
    assert_equal 'whiskey', @whiskey_item.itemtype
    assert @whiskey_item.sommelier_classification_confidence.to_f.positive?
    assert_equal 12, @whiskey_item.sommelier_parsed_fields['age_years']
    assert_in_delta 40.0, @whiskey_item.sommelier_parsed_fields['bottling_strength_abv'].to_f, 0.5

    @wine_item.reload
    assert_equal 'wine', @wine_item.itemtype
    assert @wine_item.sommelier_classification_confidence.to_f.positive?
    assert_equal 2018, @wine_item.sommelier_parsed_fields['vintage_year']
    assert_equal 750, @wine_item.sommelier_parsed_fields['size_ml']

    @run.reload
    assert_includes %w[extract_candidates resolve_entities enrich_products publish succeeded failed], @run.current_step.to_s
  end
end
