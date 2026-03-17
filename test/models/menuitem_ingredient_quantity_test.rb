require 'test_helper'

class MenuitemIngredientQuantityTest < ActiveSupport::TestCase
  def setup
    @menuitem = menuitems(:one)
    @ingredient = ingredients(:one)
    @ingredient.update!(current_cost_per_unit: 5.00)

    @quantity = MenuitemIngredientQuantity.create!(
      menuitem: @menuitem,
      ingredient: @ingredient,
      quantity: 2.5,
      unit: 'kg',
      cost_per_unit: 5.00,
    )
  end

  test 'should calculate total cost' do
    assert_equal 12.50, @quantity.total_cost
  end

  test 'should require quantity and unit' do
    @quantity.quantity = nil
    assert_not @quantity.valid?
  end

  test 'should validate positive quantity' do
    @quantity.quantity = -1
    assert_not @quantity.valid?
  end
end
