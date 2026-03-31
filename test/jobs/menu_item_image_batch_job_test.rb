# frozen_string_literal: true

require 'test_helper'

class MenuItemImageBatchJobTest < ActiveSupport::TestCase
  # MenuItemImageBatchJob iterates genimage records and calls MenuItemImageGeneratorJob.perform_sync.
  # Tests stub Sidekiq.redis and the generator job to avoid actual image generation.

  def setup
    @restaurant = restaurants(:one)
    @menu       = menus(:one)
  end

  def stub_sidekiq_redis(&)
    fake_redis = Object.new
    fake_redis.define_singleton_method(:get) { |_k| nil }
    fake_redis.define_singleton_method(:setex) { |*_args| nil }
    Sidekiq.stub(:redis, ->(*_args, &blk) { blk.call(fake_redis) }, &)
  end

  test 'perform is a no-op for a non-existent menu' do
    stub_sidekiq_redis do
      assert_nothing_raised { MenuItemImageBatchJob.new.perform(-999) }
    end
  end

  test 'perform enqueues generator job for each genimage record' do
    # Create a genimage record that has no image
    section  = menusections(:one)
    menuitem = menuitems(:one)
    Genimage.where(menu: @menu, menuitem: menuitem).destroy_all
    genimage = Genimage.create!(
      restaurant: @restaurant,
      menu: @menu,
      menusection: section,
      menuitem: menuitem,
    )

    processed_ids = []
    MenuItemImageGeneratorJob.stub(:perform_sync, lambda { |id|
      processed_ids << id
      nil
    },) do
      stub_sidekiq_redis do
        MenuItemImageBatchJob.new.perform(@menu.id)
      end
    end

    assert_includes processed_ids, genimage.id

    genimage.destroy!
  end

  test 'perform skips wine items during generation' do
    section = menusections(:one)
    wine_item = @menu.menuitems.find_by(itemtype: 'wine') ||
                Menuitem.create!(
                  name: 'Chardonnay',
                  price: 10,
                  itemtype: 'wine',
                  calories: 0,
                  menusection: section,
                  status: 1,
                  sequence: 99,
                )
    Genimage.where(menu: @menu, menuitem: wine_item).destroy_all
    wine_genimage = Genimage.create!(
      restaurant: @restaurant,
      menu: @menu,
      menusection: section,
      menuitem: wine_item,
    )

    processed_ids = []
    MenuItemImageGeneratorJob.stub(:perform_sync, lambda { |id|
      processed_ids << id
      nil
    },) do
      stub_sidekiq_redis do
        MenuItemImageBatchJob.new.perform(@menu.id)
      end
    end

    assert_not_includes processed_ids, wine_genimage.id

    wine_genimage.destroy!
    wine_item.destroy! unless @menu.menuitems.find_by(id: wine_item.id).nil?
  end
end
