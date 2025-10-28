require 'test_helper'

class IngredientTest < ActiveSupport::TestCase
  def setup
    @ingredient = ingredients(:one)
  end

  # === VALIDATION TESTS ===

  test 'should be valid with valid attributes' do
    assert @ingredient.valid?
  end

  test 'should require name' do
    @ingredient.name = nil
    assert_not @ingredient.valid?
    assert_includes @ingredient.errors[:name], "can't be blank"
  end

  # === ASSOCIATION TESTS ===

  test 'should have many menuitem_ingredient_mappings' do
    assert_respond_to @ingredient, :menuitem_ingredient_mappings
  end

  test 'should have many menuitems through mappings' do
    assert_respond_to @ingredient, :menuitems
  end

  # === FACTORY/CREATION TESTS ===

  test 'should create ingredient with valid data' do
    ingredient = Ingredient.new(name: 'Tomato')
    assert ingredient.save
    assert_equal 'Tomato', ingredient.name
  end

  test 'should create ingredient with description' do
    ingredient = Ingredient.new(
      name: 'Organic Basil',
      description: 'Fresh organic basil leaves',
    )
    assert ingredient.save
    assert_equal 'Organic Basil', ingredient.name
    assert_equal 'Fresh organic basil leaves', ingredient.description
  end

  # === DEPENDENT DESTROY TESTS ===

  test 'should have correct dependent destroy configuration' do
    reflection = Ingredient.reflect_on_association(:menuitem_ingredient_mappings)
    assert_equal :destroy, reflection.options[:dependent]
  end

  # === IDENTITY CACHE TESTS ===

  test 'should have identity cache configured' do
    assert Ingredient.respond_to?(:cache_index)
  end
end
