# frozen_string_literal: true

require 'test_helper'

class BeverageIntelligence::WhiskeyParserTest < ActiveSupport::TestCase
  setup do
    @parser = BeverageIntelligence::WhiskeyParser.new
    @menu = menus(:one)
    @section = @menu.menusections.first || Menusection.create!(
      menu: @menu, name: 'Whiskey', sequence: 1, status: :active,
    )
  end

  # ── Distillery detection ─────────────────────────────────────────

  test 'detects Islay distillery and infers region' do
    item = build_item('Lagavulin 16 Year Old', 'Rich Islay single malt')
    fields, conf = @parser.parse(item)

    assert_equal 'Lagavulin', fields['distillery']
    assert_equal 'islay', fields['whiskey_region']
    assert_equal 16, fields['age_years']
    assert conf > 0.6
  end

  test 'detects Speyside distillery' do
    item = build_item('The Macallan 18 Sherry Oak', '43% ABV')
    fields, _conf = @parser.parse(item)

    assert_equal 'Macallan', fields['distillery']
    assert_equal 'speyside', fields['whiskey_region']
    assert_equal 18, fields['age_years']
  end

  test 'detects Highland distillery' do
    item = build_item('Glenmorangie 10yo', 'Highland single malt, 40% abv')
    fields, _conf = @parser.parse(item)

    assert_equal 'Glenmorangie', fields['distillery']
    assert_equal 'highland', fields['whiskey_region']
    assert_equal 10, fields['age_years']
    assert_in_delta 40.0, fields['bottling_strength_abv'], 0.1
  end

  # ── Bourbon / American ──────────────────────────────────────────

  test 'detects bourbon distillery and type' do
    item = build_item('Buffalo Trace Bourbon', 'Kentucky straight bourbon whiskey')
    fields, _conf = @parser.parse(item)

    assert_equal 'Buffalo Trace', fields['distillery']
    assert_equal 'kentucky', fields['whiskey_region']
    assert_equal 'bourbon', fields['whiskey_type']
  end

  test 'detects Tennessee whiskey' do
    item = build_item('Jack Daniels Old No. 7', 'Tennessee whiskey, 40% abv')
    fields, _conf = @parser.parse(item)

    assert_equal 'Jack Daniels', fields['distillery']
    assert_equal 'tennessee', fields['whiskey_region']
    assert_in_delta 40.0, fields['bottling_strength_abv'], 0.1
  end

  # ── Irish ───────────────────────────────────────────────────────

  test 'detects Irish whiskey' do
    item = build_item('Redbreast 12 Year Old', 'Irish single pot still whiskey')
    fields, _conf = @parser.parse(item)

    assert_equal 'Redbreast', fields['distillery']
    assert_equal 'ireland', fields['whiskey_region']
    assert_equal 'irish_single_pot', fields['whiskey_type']
    assert_equal 12, fields['age_years']
  end

  # ── Japanese ────────────────────────────────────────────────────

  test 'detects Japanese whisky' do
    item = build_item('Yamazaki 12', 'Japanese single malt whisky, 43% abv')
    fields, _conf = @parser.parse(item)

    assert_equal 'Yamazaki', fields['distillery']
    assert_equal 'japan', fields['whiskey_region']
    assert_equal 'single_malt', fields['whiskey_type']
    assert_equal 12, fields['age_years']
  end

  # ── Cask type detection ─────────────────────────────────────────

  test 'detects sherry cask' do
    item = build_item('Aberlour 12 Sherry Cask Matured', '')
    fields, _conf = @parser.parse(item)

    assert_equal 'sherry_cask', fields['cask_type']
    assert_equal 'Aberlour', fields['distillery']
  end

  test 'detects double cask' do
    item = build_item('Macallan Double Cask 12', 'Speyside single malt')
    fields, _conf = @parser.parse(item)

    assert_equal 'double_cask', fields['cask_type']
  end

  test 'detects bourbon cask' do
    item = build_item('Laphroaig 10 Bourbon Barrel', 'Islay single malt')
    fields, _conf = @parser.parse(item)

    assert_equal 'bourbon_cask', fields['cask_type']
  end

  # ── Whiskey type detection ──────────────────────────────────────

  test 'detects single malt type' do
    item = build_item('Highland Park 12', 'Islands single malt scotch')
    fields, _conf = @parser.parse(item)

    assert_equal 'single_malt', fields['whiskey_type']
  end

  test 'detects blended scotch' do
    item = build_item('Johnnie Walker Blue Label', 'Blended scotch whisky')
    fields, _conf = @parser.parse(item)

    assert_equal 'blended_scotch', fields['whiskey_type']
  end

  test 'detects rye whiskey' do
    item = build_item('Rittenhouse Rye Whiskey', 'Bottled in bond, 50% abv')
    fields, _conf = @parser.parse(item)

    assert_equal 'rye', fields['whiskey_type']
    assert_in_delta 50.0, fields['bottling_strength_abv'], 0.1
  end

  # ── Bottler detection ───────────────────────────────────────────

  test 'detects independent bottler' do
    item = build_item('Caol Ila 12 Signatory Vintage', 'Islay single malt, cask strength')
    fields, _conf = @parser.parse(item)

    assert_equal 'IB', fields['bottler']
    assert_equal true, fields['limited_edition']
  end

  test 'defaults to OB when no IB detected' do
    item = build_item('Glenfiddich 12', 'Speyside single malt')
    fields, _conf = @parser.parse(item)

    assert_equal 'OB', fields['bottler']
  end

  # ── Limited edition detection ───────────────────────────────────

  test 'detects limited edition' do
    item = build_item('Ardbeg Supernova', 'Limited edition, 53.2% abv')
    fields, _conf = @parser.parse(item)

    assert_equal true, fields['limited_edition']
  end

  test 'detects special release' do
    item = build_item('Lagavulin Distillers Edition', 'Special release, Pedro Ximénez cask finish')
    fields, _conf = @parser.parse(item)

    assert_equal true, fields['limited_edition']
    assert_equal 'sherry_cask', fields['cask_type']
  end

  # ── Confidence scoring ──────────────────────────────────────────

  test 'confidence increases with more parsed fields' do
    minimal = build_item('Whiskey', '')
    rich = build_item('Lagavulin 16 Year Old', 'Islay single malt, sherry cask, 43% abv, limited edition')

    _, conf_minimal = @parser.parse(minimal)
    _, conf_rich = @parser.parse(rich)

    assert conf_rich > conf_minimal, "Rich item (#{conf_rich}) should score higher than minimal (#{conf_minimal})"
    assert conf_rich >= 0.9, 'Fully parsed item should have high confidence'
    assert conf_minimal <= 0.3, 'Minimal item should have low confidence'
  end

  # ── Region from text (no distillery match) ──────────────────────

  test 'detects region from explicit text when distillery unknown' do
    item = build_item('Mystery Dram', 'A fine Islay single malt')
    fields, _conf = @parser.parse(item)

    assert_equal 'islay', fields['whiskey_region']
    assert_equal 'single_malt', fields['whiskey_type']
    assert_nil fields['distillery']
  end

  private

  def build_item(name, description)
    Menuitem.create!(
      name: name,
      description: description,
      menusection: @section,
      itemtype: :food,
      status: :active,
      price: 12.0,
      preptime: 0,
      calories: 0,
    )
  end
end
