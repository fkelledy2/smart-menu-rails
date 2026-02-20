require 'test_helper'

class PairingRecommendationTest < ActiveSupport::TestCase
  def setup
    @drink = menuitems(:one)
    @food = menuitems(:two)
  end

  test 'can create a pairing recommendation' do
    rec = PairingRecommendation.create!(
      drink_menuitem: @drink,
      food_menuitem: @food,
      complement_score: 0.65,
      contrast_score: 0.3,
      score: 0.52,
      rationale: 'Shared flavors: sweet, vanilla_oak',
      risk_flags: [],
      pairing_type: 'complement',
    )
    assert rec.persisted?
    assert_equal @drink.id, rec.drink_menuitem_id
    assert_equal @food.id, rec.food_menuitem_id
  end

  test 'enforces uniqueness on drink + food pair' do
    PairingRecommendation.create!(
      drink_menuitem: @drink,
      food_menuitem: @food,
      score: 0.5,
      pairing_type: 'complement',
    )
    dup = PairingRecommendation.new(
      drink_menuitem: @drink,
      food_menuitem: @food,
      score: 0.6,
      pairing_type: 'surprise',
    )
    assert_not dup.valid?
  end

  test 'display_score returns integer percentage' do
    rec = PairingRecommendation.new(score: 0.7532)
    assert_equal 75, rec.display_score
  end

  test 'top_pairings scope orders by score desc' do
    PairingRecommendation.create!(drink_menuitem: @drink, food_menuitem: @food, score: 0.9, pairing_type: 'complement')
    results = PairingRecommendation.top_pairings(@drink.id)
    assert_equal 1, results.count
  end
end
