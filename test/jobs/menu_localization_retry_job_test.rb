# frozen_string_literal: true

require 'test_helper'

class MenuLocalizationRetryJobTest < ActiveSupport::TestCase
  test 'does nothing when rate_limited_items is blank' do
    assert_nothing_raised do
      MenuLocalizationRetryJob.new.perform([])
    end
  end

  test 'does nothing when rate_limited_items is nil' do
    assert_nothing_raised do
      MenuLocalizationRetryJob.new.perform(nil)
    end
  end

  test 'processes each item without raising when translation succeeds' do
    menu = menus(:one)

    items = [
      { 'type' => 'menu', 'id' => menu.id, 'field' => 'name', 'locale' => 'fr', 'text' => 'Menu Test' },
    ]

    # Stub the DeepL client to return a simple translation
    fake_deepl = Object.new
    fake_deepl.define_singleton_method(:translate) { |_text, _target, **_opts| 'Menu Traduit' }

    DeeplClient.stub(:new, fake_deepl) do
      assert_nothing_raised do
        MenuLocalizationRetryJob.new.perform(items)
      end
    end
  end

  test 'does not raise when an item translation fails' do
    items = [
      { 'type' => 'item', 'id' => -999_999, 'field' => 'name', 'locale' => 'de', 'text' => 'Missing item' },
    ]

    assert_nothing_raised do
      MenuLocalizationRetryJob.new.perform(items)
    end
  end

  test 'enqueues asynchronously without raising' do
    assert_nothing_raised do
      MenuLocalizationRetryJob.perform_async([])
    end
  end
end
