require 'test_helper'

class OcrMenuImportAiModeTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
  end

  test 'ai_mode defaults to normalize_only' do
    import = OcrMenuImport.new(restaurant: @restaurant, name: 'Test Menu')
    assert_equal 'normalize_only', import.ai_mode
    assert import.normalize_only?
  end

  test 'ai_mode can be set to full_enrich' do
    import = OcrMenuImport.new(restaurant: @restaurant, name: 'Test Menu', ai_mode: :full_enrich)
    assert import.full_enrich?
  end

  test 'enum values are correct' do
    assert_equal 0, OcrMenuImport.ai_modes[:normalize_only]
    assert_equal 1, OcrMenuImport.ai_modes[:full_enrich]
  end
end
