require 'test_helper'

class BeverageIntelligence::PairingEngineTest < ActiveSupport::TestCase
  def setup
    @engine = BeverageIntelligence::PairingEngine.new
    @restaurant = restaurants(:one)
    @menu = menus(:one)
    @menusection = menusections(:one)
  end

  test 'generate_for_menu returns 0 when no drink items' do
    assert_equal 0, @engine.generate_for_menu(@menu)
  end

  test 'generate_for_menu creates pairings between drinks and food' do
    # Create a drink item with sommelier category
    drink = Menuitem.create!(
      name: 'Lagavulin 16',
      menusection: @menusection,
      itemtype: :whiskey,
      status: :active,
      price: 15.0,
      preptime: 0,
      calories: 0,
    )
    FlavorProfile.create!(
      profilable: drink,
      tags: %w[smoke_peat sweet vanilla_oak],
      structure_metrics: { 'body' => 0.8, 'sweetness_level' => 0.5, 'alcohol_intensity' => 0.7 },
      provenance: 'test',
    )

    # Create a food item with rich description for tag extraction
    food = Menuitem.create!(
      name: 'Grilled Wagyu Steak with Truffle Butter',
      description: 'Charred wagyu beef with salted truffle cream, mushroom jus, and smoked paprika',
      menusection: @menusection,
      itemtype: :food,
      status: :active,
      price: 12.0,
      preptime: 10,
      calories: 200,
    )

    @menu.reload
    count = @engine.generate_for_menu(@menu)
    assert count.positive?, 'Expected at least one pairing to be created'

    pairing = PairingRecommendation.find_by(drink_menuitem_id: drink.id, food_menuitem_id: food.id)
    assert pairing.present?, 'Expected a pairing between the drink and food'
    assert pairing.score.to_f.positive?, 'Expected a positive pairing score'
    assert pairing.rationale.present?, 'Expected a rationale'
  end
end
