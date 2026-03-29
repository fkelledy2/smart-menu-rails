# frozen_string_literal: true

require 'test_helper'

class RecalculateMenuitemCostsJobTest < ActiveSupport::TestCase
  def setup
    @ingredient = ingredients(:one)
  end

  test 'does not raise when no menuitems use the ingredient' do
    # Remove any ingredient mappings for this ingredient
    MenuitemIngredientQuantity.where(ingredient_id: @ingredient.id).delete_all

    assert_nothing_raised do
      RecalculateMenuitemCostsJob.new.perform(@ingredient.id)
    end
  end

  test 'skips menuitems without a recipe_calculated active cost' do
    # Default fixture menuitems have no menuitem_costs, so the inner guard fires
    assert_nothing_raised do
      RecalculateMenuitemCostsJob.new.perform(@ingredient.id)
    end
  end

  test 'returns early without raising for missing ingredient' do
    assert_nothing_raised do
      RecalculateMenuitemCostsJob.new.perform(-999_999)
    end
  end

  test 'enqueues asynchronously without raising' do
    assert_nothing_raised do
      RecalculateMenuitemCostsJob.perform_later(@ingredient.id)
    end
  end
end
