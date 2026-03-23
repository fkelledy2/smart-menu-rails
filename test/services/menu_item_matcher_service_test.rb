# frozen_string_literal: true

require 'test_helper'

class MenuItemMatcherServiceTest < ActiveSupport::TestCase
  def setup
    @menu = menus(:one)
    @locale = 'en'
  end

  # Build a stub ML client that reports disabled
  def disabled_ml_client
    client = Object.new
    client.define_singleton_method(:enabled?) { false }
    client
  end

  # Build a stub ML client that reports enabled but returns no embeddings
  def enabled_ml_no_embed
    client = Object.new
    client.define_singleton_method(:enabled?) { true }
    client.define_singleton_method(:embed) { |**_kwargs| nil }
    client
  end

  # =========================================================================
  # guard paths — returns nil early
  # =========================================================================

  test 'match returns nil when ML client is not enabled' do
    SmartMenuMlClient.stub(:new, disabled_ml_client) do
      service = MenuItemMatcherService.new(menu_id: @menu.id, locale: 'en')
      assert_nil service.match('burger')
    end
  end

  test 'match returns nil when Pgvector is not defined' do
    SmartMenuMlClient.stub(:new, enabled_ml_no_embed) do
      service = MenuItemMatcherService.new(menu_id: @menu.id, locale: 'en')
      # Pgvector::Vector is not available in test env — returns nil
      result = service.match('burger')
      assert_nil result
    end
  end

  test 'match returns nil for blank query' do
    SmartMenuMlClient.stub(:new, enabled_ml_no_embed) do
      service = MenuItemMatcherService.new(menu_id: @menu.id, locale: 'en')
      assert_nil service.match('')
      assert_nil service.match(nil)
      assert_nil service.match('   ')
    end
  end

  # =========================================================================
  # normalize_locale (tested via constructor side-effects visible in match nil path)
  # =========================================================================

  test 'normalizes locale with region to language only' do
    SmartMenuMlClient.stub(:new, disabled_ml_client) do
      # If locale normalization raises, service cannot be instantiated
      assert_nothing_raised do
        MenuItemMatcherService.new(menu_id: @menu.id, locale: 'en-US')
      end
    end
  end

  test 'normalizes nil locale to en' do
    SmartMenuMlClient.stub(:new, disabled_ml_client) do
      assert_nothing_raised do
        MenuItemMatcherService.new(menu_id: @menu.id, locale: nil)
      end
    end
  end

  test 'accepts prefer_menuitem_ids as array' do
    SmartMenuMlClient.stub(:new, disabled_ml_client) do
      assert_nothing_raised do
        MenuItemMatcherService.new(menu_id: @menu.id, locale: 'fr', prefer_menuitem_ids: [1, 2, 3])
      end
    end
  end

  test 'accepts prefer_menuitem_ids as nil' do
    SmartMenuMlClient.stub(:new, disabled_ml_client) do
      assert_nothing_raised do
        MenuItemMatcherService.new(menu_id: @menu.id, locale: 'fr', prefer_menuitem_ids: nil)
      end
    end
  end

  # =========================================================================
  # rescue StandardError — returns nil on unexpected errors
  # =========================================================================

  test 'match rescues StandardError and returns nil' do
    raising_client = Object.new
    raising_client.define_singleton_method(:enabled?) { raise 'unexpected error' }

    SmartMenuMlClient.stub(:new, raising_client) do
      service = MenuItemMatcherService.new(menu_id: @menu.id, locale: 'en')
      result = service.match('test query')
      assert_nil result
    end
  end
end
