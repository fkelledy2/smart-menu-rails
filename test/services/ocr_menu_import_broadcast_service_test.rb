# frozen_string_literal: true

require 'test_helper'

class OcrMenuImportBroadcastServiceTest < ActiveSupport::TestCase
  test 'broadcast_progress does nothing when import is nil' do
    broadcasts = []

    ActionCable.server.stub(:broadcast, ->(*args) { broadcasts << args }) do
      OcrMenuImportBroadcastService.broadcast_progress(nil)
    end

    assert_empty broadcasts
  end

  test 'broadcast_progress does nothing when import is blank string' do
    broadcasts = []

    ActionCable.server.stub(:broadcast, ->(*args) { broadcasts << args }) do
      OcrMenuImportBroadcastService.broadcast_progress('')
    end

    assert_empty broadcasts
  end

  test 'broadcast_progress broadcasts to ocr_menu_import channel with correct structure' do
    import = ocr_menu_imports(:pending_import)
    broadcasts = []

    ActionCable.server.stub(:broadcast, ->(*args) { broadcasts << args }) do
      OcrMenuImportBroadcastService.broadcast_progress(import)
    end

    assert_equal 1, broadcasts.size
    channel, payload = broadcasts.first

    assert_equal "ocr_menu_import_#{import.id}", channel
    assert_equal 'progress', payload[:event]
    assert_equal import.id, payload[:import_id]
    assert payload.key?(:progress)
    assert payload.key?(:timestamp)
  end

  test 'broadcast_progress timestamp is an ISO 8601 string' do
    import = ocr_menu_imports(:processing_import)
    broadcasts = []

    ActionCable.server.stub(:broadcast, ->(*args) { broadcasts << args }) do
      OcrMenuImportBroadcastService.broadcast_progress(import)
    end

    timestamp = broadcasts.first.last[:timestamp]
    assert_match(/\A\d{4}-\d{2}-\d{2}T/, timestamp)
  end
end
