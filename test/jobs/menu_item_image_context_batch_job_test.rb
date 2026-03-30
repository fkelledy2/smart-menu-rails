# frozen_string_literal: true

require 'test_helper'

class MenuItemImageContextBatchJobTest < ActiveSupport::TestCase
  # MenuItemImageContextBatchJob checks fingerprints and regenerates images when they change.
  # Tests stub Sidekiq.redis and MenuItemImageGeneratorJob.

  def setup
    @restaurant = restaurants(:one)
    @menu       = menus(:one)
  end

  def stub_sidekiq_redis(&block)
    fake_redis = Object.new
    fake_redis.define_singleton_method(:get) { |_k| nil }
    fake_redis.define_singleton_method(:setex) { |*_args| nil }
    Sidekiq.stub(:redis, ->(*_args, &blk) { blk.call(fake_redis) }, &block)
  end

  test 'perform returns early for non-existent menu' do
    stub_sidekiq_redis do
      assert_nothing_raised { MenuItemImageContextBatchJob.new.perform(-999) }
    end
  end

  test 'perform processes genimages for the menu' do
    section  = menusections(:one)
    menuitem = menuitems(:one)
    Genimage.where(menu: @menu, menuitem: menuitem).destroy_all
    genimage = Genimage.create!(
      restaurant: @restaurant,
      menu: @menu,
      menusection: section,
      menuitem: menuitem,
    )

    prompt_fingerprint_calls = 0
    fake_prompt = ['A prompt text', 'some_fingerprint_hash']
    MenuItemImageGeneratorJob.stub(:build_prompt_and_fingerprint, ->(_g) { prompt_fingerprint_calls += 1; fake_prompt }) do
      MenuItemImageGeneratorJob.stub(:perform_sync, ->(_id) { nil }) do
        stub_sidekiq_redis do
          MenuItemImageContextBatchJob.new.perform(@menu.id)
        end
      end
    end

    assert prompt_fingerprint_calls > 0, 'build_prompt_and_fingerprint should have been called'

    genimage.destroy!
  end

  test 'perform handles errors per-item without raising' do
    section  = menusections(:one)
    menuitem = menuitems(:one)
    Genimage.where(menu: @menu, menuitem: menuitem).destroy_all
    genimage = Genimage.create!(
      restaurant: @restaurant,
      menu: @menu,
      menusection: section,
      menuitem: menuitem,
    )

    MenuItemImageGeneratorJob.stub(:build_prompt_and_fingerprint, ->(_g) { raise StandardError, 'AI error' }) do
      stub_sidekiq_redis do
        assert_nothing_raised { MenuItemImageContextBatchJob.new.perform(@menu.id) }
      end
    end

    genimage.destroy!
  end
end
