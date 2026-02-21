# frozen_string_literal: true

require 'test_helper'

class BeverageIntelligence::WhiskeyCsvImporterTest < ActiveSupport::TestCase
  setup do
    @menu = menus(:one)
    @section = @menu.menusections.first || Menusection.create!(
      menu: @menu, name: 'Whiskey', sequence: 1, status: :active
    )

    @lagavulin = Menuitem.create!(
      name: 'Lagavulin 16yo', description: 'Islay single malt',
      menusection: @section, itemtype: :food, status: :active,
      price: 18.0, preptime: 0, calories: 0,
      sommelier_category: 'whiskey', sommelier_parsed_fields: {},
    )
    @macallan = Menuitem.create!(
      name: 'Macallan 12 Double Cask', description: 'Speyside single malt',
      menusection: @section, itemtype: :food, status: :active,
      price: 14.0, preptime: 0, calories: 0,
      sommelier_category: 'whiskey', sommelier_parsed_fields: {},
    )
    @redbreast = Menuitem.create!(
      name: 'Redbreast 12', description: 'Irish single pot still',
      menusection: @section, itemtype: :food, status: :active,
      price: 12.0, preptime: 0, calories: 0,
      sommelier_category: 'whiskey', sommelier_parsed_fields: {},
    )
  end

  test 'imports valid CSV and matches items' do
    csv = <<~CSV
      menu_item_name,whiskey_type,whiskey_region,distillery,cask_type,staff_flavor_cluster,staff_tasting_note,staff_pick
      "Lagavulin 16yo",single_malt,islay,Lagavulin,sherry_cask,heavily_peated,"Rich medicinal peat",true
      "Macallan 12 Double Cask",single_malt,speyside,Macallan,double_cask,rich_sherried,"Sherry sweetness with vanilla",false
    CSV

    importer = BeverageIntelligence::WhiskeyCsvImporter.new(@menu)
    result = importer.import(csv)

    assert_equal 2, result.matched.size
    assert_equal 0, result.unmatched.size
    assert_equal 0, result.errors.size

    @lagavulin.reload
    parsed = @lagavulin.sommelier_parsed_fields
    assert_equal 'islay', parsed['whiskey_region']
    assert_equal 'Lagavulin', parsed['distillery']
    assert_equal 'heavily_peated', parsed['staff_flavor_cluster']
    assert_equal 'Rich medicinal peat', parsed['staff_tasting_note']
    assert_equal true, parsed['staff_pick']
    assert parsed['staff_tagged_at'].present?
  end

  test 'fuzzy matches items with minor name differences' do
    csv = <<~CSV
      menu_item_name,whiskey_region,distillery
      "Lagavulin 16 Year Old",islay,Lagavulin
    CSV

    importer = BeverageIntelligence::WhiskeyCsvImporter.new(@menu)
    result = importer.import(csv)

    assert_equal 1, result.matched.size
    assert_equal @lagavulin.id, result.matched.first[:menuitem_id]
  end

  test 'reports unmatched rows' do
    csv = <<~CSV
      menu_item_name,whiskey_region
      "Unknown Whiskey XYZ",islay
    CSV

    importer = BeverageIntelligence::WhiskeyCsvImporter.new(@menu)
    result = importer.import(csv)

    assert_equal 0, result.matched.size
    assert_equal 1, result.unmatched.size
    assert_equal 'Unknown Whiskey XYZ', result.unmatched.first[:name]
  end

  test 'reports errors for blank menu_item_name' do
    csv = <<~CSV
      menu_item_name,whiskey_region
      "",islay
    CSV

    importer = BeverageIntelligence::WhiskeyCsvImporter.new(@menu)
    result = importer.import(csv)

    assert_equal 1, result.errors.size
    assert_match(/blank/, result.errors.first)
  end

  test 'reports errors for rows with no tagging fields' do
    csv = <<~CSV
      menu_item_name
      "Lagavulin 16yo"
    CSV

    importer = BeverageIntelligence::WhiskeyCsvImporter.new(@menu)
    result = importer.import(csv)

    assert_equal 0, result.matched.size
    assert_equal 1, result.errors.size
    assert_match(/no tagging fields/, result.errors.first)
  end

  test 'raises on missing required headers' do
    csv = <<~CSV
      whiskey_region,distillery
      islay,Lagavulin
    CSV

    importer = BeverageIntelligence::WhiskeyCsvImporter.new(@menu)
    assert_raises(ArgumentError) { importer.import(csv) }
  end

  test 'imports age and abv fields' do
    csv = <<~CSV
      menu_item_name,age,abv,whiskey_region
      "Redbreast 12",12,40.0,ireland
    CSV

    importer = BeverageIntelligence::WhiskeyCsvImporter.new(@menu)
    result = importer.import(csv)

    assert_equal 1, result.matched.size

    @redbreast.reload
    parsed = @redbreast.sommelier_parsed_fields
    assert_equal 12, parsed['age_years']
    assert_in_delta 40.0, parsed['bottling_strength_abv'], 0.1
    assert_equal 'ireland', parsed['whiskey_region']
  end

  test 'merges with existing parsed fields' do
    @lagavulin.update_columns(sommelier_parsed_fields: { 'name_raw' => 'Lagavulin 16yo', 'age_years' => 16 })

    csv = <<~CSV
      menu_item_name,whiskey_region,staff_tasting_note
      "Lagavulin 16yo",islay,"Medicinal peat"
    CSV

    importer = BeverageIntelligence::WhiskeyCsvImporter.new(@menu)
    result = importer.import(csv)

    assert_equal 1, result.matched.size
    @lagavulin.reload
    parsed = @lagavulin.sommelier_parsed_fields
    assert_equal 16, parsed['age_years'], 'Pre-existing age_years should be preserved'
    assert_equal 'islay', parsed['whiskey_region'], 'Imported region should be added'
    assert_equal 'Medicinal peat', parsed['staff_tasting_note']
  end
end
