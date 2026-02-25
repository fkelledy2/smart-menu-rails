require 'test_helper'

class BeverageIntelligence::RecommenderTest < ActiveSupport::TestCase
  def setup
    @recommender = BeverageIntelligence::Recommender.new
    @menu = menus(:one)
    @menusection = menusections(:one)
  end

  test 'generate_for_menu returns 0 with fewer than 2 products' do
    assert_equal 0, @recommender.generate_for_menu(@menu)
  end

  test 'recommend_for_guest returns scored results based on preferences' do
    drink = Menuitem.create!(
      name: 'Peated Scotch', menusection: @menusection,
      itemtype: :whiskey, status: :active,
      price: 12.0, preptime: 0, calories: 0,
    )
    FlavorProfile.create!(
      profilable: drink,
      tags: %w[smoke_peat sweet vanilla_oak],
      structure_metrics: { 'body' => 0.8, 'sweetness_level' => 0.5, 'peat_level' => 0.7, 'alcohol_intensity' => 0.6 },
      provenance: 'test',
    )

    results = @recommender.recommend_for_guest(
      menu: @menu,
      preferences: { smoky: true, taste: 'sweet', budget: 2 },
      limit: 3,
    )
    assert results.is_a?(Array)
    assert results.size >= 1, 'Expected at least one recommendation'
    assert results.first[:menuitem].id == drink.id
    assert results.first[:score].positive?
  end

  test 'recommend_for_guest penalizes smoky drinks when smoky=false' do
    smoky_drink = Menuitem.create!(
      name: 'Heavy Peat', menusection: @menusection,
      itemtype: :whiskey, status: :active,
      price: 14.0, preptime: 0, calories: 0,
    )
    FlavorProfile.create!(
      profilable: smoky_drink,
      tags: %w[smoke_peat],
      structure_metrics: { 'peat_level' => 0.9, 'body' => 0.7 },
      provenance: 'test',
    )

    clean_drink = Menuitem.create!(
      name: 'Speyside Malt', menusection: @menusection,
      itemtype: :whiskey, status: :active,
      price: 14.0, preptime: 0, calories: 0,
    )
    FlavorProfile.create!(
      profilable: clean_drink,
      tags: %w[sweet vanilla_oak honey],
      structure_metrics: { 'peat_level' => 0.0, 'sweetness_level' => 0.7, 'body' => 0.5 },
      provenance: 'test',
    )

    results = @recommender.recommend_for_guest(
      menu: @menu,
      preferences: { smoky: false, taste: 'sweet', budget: 2 },
      limit: 3,
    )

    assert results.size >= 1
    # The clean drink should rank higher
    if results.size >= 2
      assert results.first[:menuitem].id == clean_drink.id,
             'Expected non-smoky drink to rank first when smoky=false'
    end
  end
end
