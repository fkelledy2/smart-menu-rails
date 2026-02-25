# frozen_string_literal: true

require 'test_helper'

class BeverageIntelligence::WineRecommenderTest < ActiveSupport::TestCase
  setup do
    @menu = menus(:one)
    @menusection = @menu.menusections.first || Menusection.create!(
      menu: @menu, name: 'Wine List', sequence: 1, status: :active,
    )
    @recommender = BeverageIntelligence::Recommender.new

    # Create wine items with sommelier fields
    @red_wine = Menuitem.create!(
      name: 'Chianti Classico Riserva',
      description: 'Full-bodied Sangiovese from Tuscany',
      menusection: @menusection, itemtype: :wine, status: :active,
      price: 28.0, preptime: 0, calories: 0,
      sommelier_parsed_fields: { 'wine_color' => 'red', 'grape_variety' => ['sangiovese'], 'appellation' => 'chianti' },
    )
    FlavorProfile.create!(
      profilable: @red_wine,
      tags: %w[berry earthy herbal tannic],
      structure_metrics: { 'body' => 0.7, 'tannin' => 0.6, 'acidity' => 0.5, 'sweetness_level' => 0.2 },
      provenance: 'test',
    )

    @white_wine = Menuitem.create!(
      name: 'Sancerre Sauvignon Blanc',
      description: 'Crisp and zesty Loire white',
      menusection: @menusection, itemtype: :wine, status: :active,
      price: 14.0, preptime: 0, calories: 0,
      sommelier_parsed_fields: { 'wine_color' => 'white', 'grape_variety' => ['sauvignon blanc'], 'appellation' => 'sancerre' },
    )
    FlavorProfile.create!(
      profilable: @white_wine,
      tags: %w[citrus herbal floral],
      structure_metrics: { 'body' => 0.35, 'tannin' => 0.1, 'acidity' => 0.7, 'sweetness_level' => 0.15 },
      provenance: 'test',
    )

    @menu.reload
  end

  test 'recommend_wines_for_guest returns wine results' do
    results = @recommender.recommend_wines_for_guest(
      menu: @menu,
      preferences: { wine_color: 'red', body: 'full', taste: 'dry', budget: 2 },
      limit: 3,
    )
    assert results.size.positive?, 'Expected at least one wine recommendation'
    assert results.first[:wine_color].present? || results.first[:tags].any?
  end

  test 'wine color preference boosts matching wines' do
    red_results = @recommender.recommend_wines_for_guest(
      menu: @menu,
      preferences: { wine_color: 'red', body: 'full', taste: 'dry', budget: 2 },
      limit: 3,
    )
    white_results = @recommender.recommend_wines_for_guest(
      menu: @menu,
      preferences: { wine_color: 'white', body: 'light', taste: 'dry', budget: 1 },
      limit: 3,
    )

    # Red preference should rank the red wine higher
    red_top = red_results.first
    white_top = white_results.first

    assert_equal @red_wine.id, red_top[:menuitem].id, 'Red wine should be top pick for red preference'
    assert_equal @white_wine.id, white_top[:menuitem].id, 'White wine should be top pick for white preference'
  end

  test 'body preference affects scoring' do
    light_results = @recommender.recommend_wines_for_guest(
      menu: @menu,
      preferences: { wine_color: 'no_preference', body: 'light', taste: 'dry', budget: 1 },
      limit: 3,
    )

    # White wine (body 0.35) should score higher for light preference
    assert light_results.first[:menuitem].id == @white_wine.id,
           'Light body preference should favour the lighter wine'
  end

  test 'results include wine metadata fields' do
    results = @recommender.recommend_wines_for_guest(
      menu: @menu,
      preferences: { wine_color: 'red', body: 'medium', taste: 'dry', budget: 2 },
      limit: 3,
    )
    rec = results.find { |r| r[:menuitem].id == @red_wine.id }
    assert rec, 'Expected red wine in results'
    assert_equal 'red', rec[:wine_color]
    assert_equal 'sangiovese', rec[:grape_variety]
    assert_equal 'chianti', rec[:appellation]
  end
end
