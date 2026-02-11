require 'test_helper'

class ImportToMenuItemtypeTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
    @import = @restaurant.ocr_menu_imports.create!(name: 'Test Import', status: 'completed')
  end

  test 'infer_default_itemtype returns wine for wine keywords' do
    service = ImportToMenu.new(restaurant: @restaurant, import: @import)
    assert_equal 'wine', service.send(:infer_default_itemtype, section_name: 'Red Wines', item_name: 'Chianti Classico')
    assert_equal 'wine', service.send(:infer_default_itemtype, section_name: 'Sparkling', item_name: 'Prosecco Brut')
    assert_equal 'wine', service.send(:infer_default_itemtype, section_name: 'Menu', item_name: 'Champagne Dom Perignon')
  end

  test 'infer_default_itemtype returns beverage for drink keywords' do
    service = ImportToMenu.new(restaurant: @restaurant, import: @import)
    assert_equal 'beverage', service.send(:infer_default_itemtype, section_name: 'Cocktails', item_name: 'Negroni')
    assert_equal 'beverage', service.send(:infer_default_itemtype, section_name: 'Draught', item_name: 'Guinness')
    assert_equal 'beverage', service.send(:infer_default_itemtype, section_name: 'Spirits', item_name: 'Jameson Irish Whiskey')
  end

  test 'infer_default_itemtype returns food for food keywords' do
    service = ImportToMenu.new(restaurant: @restaurant, import: @import)
    assert_equal 'food', service.send(:infer_default_itemtype, section_name: 'Starters', item_name: 'Bruschetta')
    assert_equal 'food', service.send(:infer_default_itemtype, section_name: 'Main Course', item_name: 'Grilled Salmon')
    assert_equal 'food', service.send(:infer_default_itemtype, section_name: 'Desserts', item_name: 'Tiramisu')
  end

  test 'infer_default_itemtype falls back to venue type for wine_bar' do
    @restaurant.update_columns(establishment_types: ['wine_bar'])
    service = ImportToMenu.new(restaurant: @restaurant, import: @import)
    assert_equal 'wine', service.send(:infer_default_itemtype, section_name: 'Specials', item_name: 'House Selection')
  end

  test 'infer_default_itemtype falls back to venue type for bar' do
    @restaurant.update_columns(establishment_types: ['bar'])
    service = ImportToMenu.new(restaurant: @restaurant, import: @import)
    assert_equal 'beverage', service.send(:infer_default_itemtype, section_name: 'Specials', item_name: 'House Selection')
  end

  test 'infer_default_itemtype falls back to food for restaurant' do
    @restaurant.update_columns(establishment_types: ['restaurant'])
    service = ImportToMenu.new(restaurant: @restaurant, import: @import)
    assert_equal 'food', service.send(:infer_default_itemtype, section_name: 'Specials', item_name: 'House Selection')
  end

  test 'infer_default_itemtype falls back to food when no types set' do
    @restaurant.update_columns(establishment_types: [])
    service = ImportToMenu.new(restaurant: @restaurant, import: @import)
    assert_equal 'food', service.send(:infer_default_itemtype, section_name: 'Specials', item_name: 'House Selection')
  end
end
