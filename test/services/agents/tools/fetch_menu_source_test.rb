# frozen_string_literal: true

require 'test_helper'

class Agents::Tools::FetchMenuSourceTest < ActiveSupport::TestCase
  def setup
    @import = ocr_menu_imports(:completed_import)
  end

  test 'returns correct shape' do
    result = Agents::Tools::FetchMenuSource.call('ocr_menu_import_id' => @import.id)
    assert_equal @import.id, result[:ocr_menu_import_id]
    assert result.key?(:sections)
    assert result.key?(:sections_count)
    assert result.key?(:items_count)
  end

  test 'includes section and item data' do
    result = Agents::Tools::FetchMenuSource.call('ocr_menu_import_id' => @import.id)
    assert result[:sections].is_a?(Array)
  end

  test 'tool_name is fetch_menu_source' do
    assert_equal 'fetch_menu_source', Agents::Tools::FetchMenuSource.tool_name
  end

  test 'raises when import not found' do
    assert_raises ActiveRecord::RecordNotFound do
      Agents::Tools::FetchMenuSource.call('ocr_menu_import_id' => 999_999)
    end
  end

  test 'accepts symbol keys' do
    result = Agents::Tools::FetchMenuSource.call(ocr_menu_import_id: @import.id)
    assert_equal @import.id, result[:ocr_menu_import_id]
  end
end
