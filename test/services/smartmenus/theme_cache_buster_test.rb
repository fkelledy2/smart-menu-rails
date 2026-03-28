# frozen_string_literal: true

require 'test_helper'

class Smartmenus::ThemeCacheBusterTest < ActiveSupport::TestCase
  def setup
    @smartmenu = smartmenus(:one)
  end

  test 'call delegates to Rails.cache.delete_matched with a key pattern scoped to the smartmenu id' do
    deleted_pattern = nil

    Rails.cache.stub(:delete_matched, ->(pattern) { deleted_pattern = pattern }) do
      Smartmenus::ThemeCacheBuster.new(@smartmenu).call
    end

    assert_not_nil deleted_pattern
    assert_includes deleted_pattern, @smartmenu.id.to_s,
                    'Cache bust key pattern must include the smartmenu id'
  end

  test 'call invokes delete_matched exactly once' do
    call_count = 0

    Rails.cache.stub(:delete_matched, ->(_) { call_count += 1 }) do
      Smartmenus::ThemeCacheBuster.new(@smartmenu).call
    end

    assert_equal 1, call_count
  end
end
