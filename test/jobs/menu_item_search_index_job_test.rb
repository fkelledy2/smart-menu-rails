# frozen_string_literal: true

require 'test_helper'

class MenuItemSearchIndexJobTest < ActiveSupport::TestCase
  def setup
    @menu = menus(:one)
    @job = MenuItemSearchIndexJob.new
  end

  test 'does not raise when vector search is disabled' do
    ENV['SMART_MENU_VECTOR_SEARCH_ENABLED'] = 'false'
    assert_nothing_raised do
      @job.perform(@menu.id)
    end
  ensure
    ENV.delete('SMART_MENU_VECTOR_SEARCH_ENABLED')
  end

  test 'does not raise when menu does not exist' do
    ENV['SMART_MENU_VECTOR_SEARCH_ENABLED'] = 'false'
    assert_nothing_raised do
      @job.perform(-999_999)
    end
  ensure
    ENV.delete('SMART_MENU_VECTOR_SEARCH_ENABLED')
  end

  test 'normalize_locale strips language subtag' do
    assert_equal 'en', @job.send(:normalize_locale, 'en-US')
    assert_equal 'fr', @job.send(:normalize_locale, 'fr-FR')
    assert_equal 'de', @job.send(:normalize_locale, 'de_DE')
  end

  test 'normalize_locale handles blank' do
    assert_equal 'en', @job.send(:normalize_locale, '')
    assert_equal 'en', @job.send(:normalize_locale, nil)
  end

  test 'normalize_locale downcases locale' do
    assert_equal 'en', @job.send(:normalize_locale, 'EN')
  end

  test 'enqueues without raising' do
    assert_nothing_raised do
      MenuItemSearchIndexJob.perform_async(@menu.id)
    end
  end
end
