# frozen_string_literal: true

require 'test_helper'

class BeverageIntelligence::WineParserTest < ActiveSupport::TestCase
  setup do
    @parser = BeverageIntelligence::WineParser.new
    @menu = menus(:one)
    @menusection = @menu.menusections.first || Menusection.create!(
      menu: @menu, name: 'Red Wines', sequence: 1, status: :active
    )
  end

  test 'detects grape variety from item name' do
    item = Menuitem.create!(
      name: 'Château Margaux Cabernet Sauvignon 2018',
      description: 'Full-bodied Bordeaux red',
      menusection: @menusection, itemtype: :food, status: :active,
      price: 45.0, preptime: 0, calories: 0,
    )
    fields, conf = @parser.parse(item)

    assert_includes fields['grape_variety'], 'cabernet sauvignon'
    assert_equal 2018, fields['vintage_year']
    assert conf > 0.5
  end

  test 'detects Italian appellation' do
    item = Menuitem.create!(
      name: 'Barolo Riserva 2016',
      description: 'Nebbiolo grapes from Piemonte',
      menusection: @menusection, itemtype: :food, status: :active,
      price: 65.0, preptime: 0, calories: 0,
    )
    fields, conf = @parser.parse(item)

    assert_equal 'barolo', fields['appellation']
    assert_includes fields['grape_variety'], 'nebbiolo'
    assert_equal 2016, fields['vintage_year']
    assert_equal 'Riserva', fields['classification']
    assert conf > 0.6
  end

  test 'detects wine color from section name' do
    white_section = Menusection.create!(
      menu: @menu, name: 'White Wines', sequence: 2, status: :active
    )
    item = Menuitem.create!(
      name: 'Cloudy Bay Sauvignon Blanc',
      description: 'Crisp and zesty New Zealand white',
      menusection: white_section, itemtype: :food, status: :active,
      price: 12.0, preptime: 0, calories: 0,
    )
    fields, _conf = @parser.parse(item)

    assert_equal 'white', fields['wine_color']
    assert_includes fields['grape_variety'], 'sauvignon blanc'
  end

  test 'infers color from grape when section does not indicate color' do
    item = Menuitem.create!(
      name: 'Pinot Noir Reserve',
      description: 'Elegant and earthy',
      menusection: @menusection, itemtype: :food, status: :active,
      price: 18.0, preptime: 0, calories: 0,
    )
    fields, _conf = @parser.parse(item)

    assert_equal 'red', fields['wine_color']
    assert_includes fields['grape_variety'], 'pinot noir'
  end

  test 'detects sparkling wine' do
    item = Menuitem.create!(
      name: 'Moët & Chandon Brut Impérial',
      description: 'Classic Champagne',
      menusection: @menusection, itemtype: :food, status: :active,
      price: 55.0, preptime: 0, calories: 0,
    )
    fields, _conf = @parser.parse(item)

    assert_equal 'sparkling', fields['wine_color']
  end

  test 'detects serve type glass vs bottle' do
    item = Menuitem.create!(
      name: 'House Merlot (Glass)',
      description: '175ml glass',
      menusection: @menusection, itemtype: :food, status: :active,
      price: 7.0, preptime: 0, calories: 0,
    )
    fields, _conf = @parser.parse(item)

    assert_equal 'glass', fields['serve_type']
  end

  test 'detects classification DOC DOCG' do
    item = Menuitem.create!(
      name: 'Chianti Classico DOCG 2019',
      description: 'Sangiovese from Tuscany',
      menusection: @menusection, itemtype: :food, status: :active,
      price: 22.0, preptime: 0, calories: 0,
    )
    fields, _conf = @parser.parse(item)

    assert_equal 'DOCG', fields['classification']
    assert_equal 'chianti', fields['appellation']
    assert_equal 2019, fields['vintage_year']
  end

  test 'extracts producer from wine name' do
    item = Menuitem.create!(
      name: 'Antinori Chianti Classico Riserva',
      description: 'Premium Tuscan red',
      menusection: @menusection, itemtype: :food, status: :active,
      price: 35.0, preptime: 0, calories: 0,
    )
    fields, _conf = @parser.parse(item)

    assert fields['producer'].present?, "Expected producer to be extracted"
  end

  test 'confidence increases with more parsed fields' do
    minimal = Menuitem.create!(
      name: 'Red Wine', description: '',
      menusection: @menusection, itemtype: :food, status: :active,
      price: 8.0, preptime: 0, calories: 0,
    )
    rich = Menuitem.create!(
      name: 'Château Margaux Cabernet Sauvignon 2018 DOCG',
      description: 'Full-bodied Bordeaux red, 750ml bottle',
      menusection: @menusection, itemtype: :food, status: :active,
      price: 90.0, preptime: 0, calories: 0,
    )

    _, conf_minimal = @parser.parse(minimal)
    _, conf_rich = @parser.parse(rich)

    assert conf_rich > conf_minimal, "Rich wine should have higher confidence"
  end
end
