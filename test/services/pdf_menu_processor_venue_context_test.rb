require 'test_helper'

class PdfMenuProcessorVenueContextTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
    @import = @restaurant.ocr_menu_imports.create!(name: 'Test', status: 'pending')
  end

  test 'build_venue_context returns restaurant label for standard restaurants' do
    @restaurant.update_columns(establishment_types: ['restaurant'])
    processor = PdfMenuProcessor.new(@import)
    ctx = processor.send(:build_venue_context)
    assert_includes ctx[:label], 'restaurant'
    assert_includes ctx[:instructions], 'RESTAURANT MENU GUIDANCE'
  end

  test 'build_venue_context returns wine bar label and instructions' do
    @restaurant.update_columns(establishment_types: ['wine_bar'])
    processor = PdfMenuProcessor.new(@import)
    ctx = processor.send(:build_venue_context)
    assert_includes ctx[:label], 'wine bar'
    assert_includes ctx[:instructions], 'WINE LIST GUIDANCE'
    assert_includes ctx[:instructions], 'vintage'
  end

  test 'build_venue_context returns whiskey bar label and instructions' do
    @restaurant.update_columns(establishment_types: ['whiskey_bar'])
    processor = PdfMenuProcessor.new(@import)
    ctx = processor.send(:build_venue_context)
    assert_includes ctx[:label], 'whiskey/spirits bar'
    assert_includes ctx[:instructions], 'SPIRITS/WHISKEY MENU GUIDANCE'
    assert_includes ctx[:instructions], 'ABV'
  end

  test 'build_venue_context returns bar label and instructions' do
    @restaurant.update_columns(establishment_types: ['bar'])
    processor = PdfMenuProcessor.new(@import)
    ctx = processor.send(:build_venue_context)
    assert_includes ctx[:label], 'bar'
    assert_includes ctx[:instructions], 'BAR/COCKTAIL MENU GUIDANCE'
  end

  test 'build_venue_context combines multiple types' do
    @restaurant.update_columns(establishment_types: %w[restaurant wine_bar])
    processor = PdfMenuProcessor.new(@import)
    ctx = processor.send(:build_venue_context)
    assert_includes ctx[:label], 'wine bar'
    assert_includes ctx[:label], 'restaurant'
    assert_includes ctx[:instructions], 'WINE LIST GUIDANCE'
    assert_includes ctx[:instructions], 'RESTAURANT MENU GUIDANCE'
  end

  test 'build_venue_context defaults to restaurant when no types' do
    @restaurant.update_columns(establishment_types: [])
    processor = PdfMenuProcessor.new(@import)
    ctx = processor.send(:build_venue_context)
    assert_equal 'restaurant', ctx[:label]
    assert_includes ctx[:instructions], 'RESTAURANT MENU GUIDANCE'
  end
end
