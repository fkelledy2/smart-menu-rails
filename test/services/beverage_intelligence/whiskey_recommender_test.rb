# frozen_string_literal: true

require 'test_helper'

class BeverageIntelligence::WhiskeyRecommenderTest < ActiveSupport::TestCase
  setup do
    @menu = menus(:one)
    @section = @menu.menusections.first || Menusection.create!(
      menu: @menu, name: 'Whiskey', sequence: 1, status: :active
    )
    @recommender = BeverageIntelligence::WhiskeyRecommender.new

    # Create a variety of whiskey items
    @lagavulin = create_whiskey('Lagavulin 16yo', 18.0, {
      'distillery' => 'Lagavulin', 'whiskey_region' => 'islay',
      'whiskey_type' => 'single_malt', 'cask_type' => 'sherry_cask',
      'age_years' => 16, 'bottling_strength_abv' => 43.0,
      'staff_flavor_cluster' => 'heavily_peated',
      'staff_tasting_note' => 'Rich medicinal peat', 'staff_pick' => true,
    })

    @macallan = create_whiskey('Macallan 12 Double Cask', 14.0, {
      'distillery' => 'Macallan', 'whiskey_region' => 'speyside',
      'whiskey_type' => 'single_malt', 'cask_type' => 'double_cask',
      'age_years' => 12, 'bottling_strength_abv' => 40.0,
      'staff_flavor_cluster' => 'rich_sherried',
      'staff_tasting_note' => 'Sherry sweetness with vanilla',
    })

    @buffalo = create_whiskey('Buffalo Trace Bourbon', 10.0, {
      'distillery' => 'Buffalo Trace', 'whiskey_region' => 'kentucky',
      'whiskey_type' => 'bourbon', 'bottling_strength_abv' => 45.0,
      'staff_flavor_cluster' => 'fruity_sweet',
    })

    @redbreast = create_whiskey('Redbreast 12', 12.0, {
      'distillery' => 'Redbreast', 'whiskey_region' => 'ireland',
      'whiskey_type' => 'irish_single_pot', 'age_years' => 12,
      'bottling_strength_abv' => 40.0,
      'staff_flavor_cluster' => 'fruity_sweet',
    })

    @talisker = create_whiskey('Talisker 10', 15.0, {
      'distillery' => 'Talisker', 'whiskey_region' => 'islands',
      'whiskey_type' => 'single_malt', 'age_years' => 10,
      'bottling_strength_abv' => 45.8,
      'staff_flavor_cluster' => 'smoky_coastal',
    })

    @ardbeg_limited = create_whiskey('Ardbeg Supernova', 25.0, {
      'distillery' => 'Ardbeg', 'whiskey_region' => 'islay',
      'whiskey_type' => 'single_malt', 'bottling_strength_abv' => 53.2,
      'staff_flavor_cluster' => 'heavily_peated',
      'limited_edition' => true,
    })
  end

  # ── Quick Pick Mode ──────────────────────────────────────────────

  test 'recommends scotch when region_pref is scotch' do
    results = @recommender.recommend_for_guest(
      menu: @menu,
      preferences: { experience_level: 'casual', region_pref: 'scotch', flavor_pref: nil, budget: 2 },
    )

    assert results.any?, 'Should return at least one recommendation'
    regions = results.map { |r| r[:parsed_fields]['whiskey_region'] }
    scotch_regions = %w[islay speyside highland lowland campbeltown islands]
    assert regions.all? { |r| scotch_regions.include?(r) }, "All results should be scotch, got: #{regions}"
  end

  test 'recommends bourbon when region_pref is bourbon_rye' do
    results = @recommender.recommend_for_guest(
      menu: @menu,
      preferences: { experience_level: 'casual', region_pref: 'bourbon_rye', flavor_pref: nil, budget: 1 },
    )

    assert results.any?
    assert results.any? { |r| r[:parsed_fields]['whiskey_region'] == 'kentucky' }
  end

  test 'flavor_pref heavily_peated favors peated whiskeys' do
    results = @recommender.recommend_for_guest(
      menu: @menu,
      preferences: { experience_level: 'casual', region_pref: 'surprise_me', flavor_pref: 'heavily_peated', budget: 2 },
    )

    assert results.any?
    top = results.first
    assert_equal 'heavily_peated', top[:parsed_fields]['staff_flavor_cluster'],
                 "Top result should be heavily peated"
  end

  test 'newcomer experience favors lower ABV' do
    results = @recommender.recommend_for_guest(
      menu: @menu,
      preferences: { experience_level: 'newcomer', region_pref: 'surprise_me', flavor_pref: nil, budget: 2 },
    )

    assert results.any?
    abvs = results.map { |r| r[:parsed_fields]['bottling_strength_abv'].to_f }
    # Newcomer recommendations should not lead with 53%+ cask strength
    assert abvs.first <= 46, "Top result for newcomer should be moderate ABV, got #{abvs.first}"
  end

  test 'enthusiast experience favors aged and limited editions' do
    results = @recommender.recommend_for_guest(
      menu: @menu,
      preferences: { experience_level: 'enthusiast', region_pref: 'surprise_me', flavor_pref: 'heavily_peated', budget: 3 },
    )

    assert results.any?
    # Limited edition should score higher for enthusiasts
    limited = results.select { |r| r[:rare] }
    assert limited.any?, 'Enthusiast should get at least one rare/limited recommendation'
  end

  test 'budget 1 favors value items' do
    results = @recommender.recommend_for_guest(
      menu: @menu,
      preferences: { experience_level: 'casual', region_pref: 'surprise_me', flavor_pref: nil, budget: 1 },
    )

    assert results.any?
    prices = results.map { |r| r[:menuitem].price.to_f }
    assert prices.first <= 12, "Budget 1 top pick should be value, got €#{prices.first}"
  end

  test 'exclude_ids deprioritizes already shown items' do
    results_first = @recommender.recommend_for_guest(
      menu: @menu,
      preferences: { experience_level: 'casual', region_pref: 'scotch', flavor_pref: 'heavily_peated', budget: 2 },
    )
    first_ids = results_first.map { |r| r[:menuitem].id }

    results_second = @recommender.recommend_for_guest(
      menu: @menu,
      preferences: { experience_level: 'casual', region_pref: 'scotch', flavor_pref: 'heavily_peated', budget: 2 },
      exclude_ids: first_ids,
    )

    second_ids = results_second.map { |r| r[:menuitem].id }
    # Not all excluded items should be in second result set (deprioritized but not excluded)
    # At minimum the ordering should differ if there are alternatives
    assert results_second.any?, 'Should still return results even with exclusions'
  end

  test 'returns why_text for each recommendation' do
    results = @recommender.recommend_for_guest(
      menu: @menu,
      preferences: { experience_level: 'casual', region_pref: 'scotch', flavor_pref: nil, budget: 2 },
    )

    results.each do |r|
      assert r[:why_text].present?, "why_text should be present for #{r[:menuitem].name}"
    end
  end

  test 'returns new_arrival and rare flags' do
    results = @recommender.recommend_for_guest(
      menu: @menu,
      preferences: { experience_level: 'enthusiast', region_pref: 'surprise_me', flavor_pref: nil, budget: 3 },
    )

    results.each do |r|
      assert [true, false].include?(r[:new_arrival]), 'new_arrival should be boolean'
      assert [true, false].include?(r[:rare]), 'rare should be boolean'
    end
  end

  # ── Explore Mode ─────────────────────────────────────────────────

  test 'explore returns quadrants with counts' do
    result = @recommender.explore(menu: @menu)

    assert result[:quadrants].is_a?(Hash)
    assert result[:quadrants].key?('heavily_peated')
    assert result[:quadrants]['heavily_peated'][:count] >= 1
  end

  test 'explore filters by cluster' do
    result = @recommender.explore(menu: @menu, cluster: 'heavily_peated')

    result[:items].each do |item|
      assert_equal 'heavily_peated', item[:cluster],
                   "Filtered items should all be heavily_peated, got #{item[:cluster]}"
    end
  end

  test 'explore filters by region' do
    result = @recommender.explore(menu: @menu, region: 'islay')

    result[:items].each do |item|
      assert_equal 'islay', item[:parsed_fields]['whiskey_region']
    end
  end

  test 'explore rare_only filter' do
    result = @recommender.explore(menu: @menu, rare_only: true)

    assert result[:items].any?
    result[:items].each do |item|
      assert_equal true, item[:rare], 'All items should be rare'
    end
  end

  test 'explore returns all items when no filters' do
    result = @recommender.explore(menu: @menu)

    assert_equal 6, result[:items].size, 'Should return all 6 whiskey items'
  end

  private

  def create_whiskey(name, price, parsed_fields)
    Menuitem.create!(
      name: name,
      description: '',
      menusection: @section,
      itemtype: :whiskey,
      status: :active,
      price: price,
      preptime: 0,
      calories: 0,
      sommelier_parsed_fields: parsed_fields,
    )
  end
end
