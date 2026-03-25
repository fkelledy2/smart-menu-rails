# frozen_string_literal: true

require 'test_helper'

class FloorplanBroadcastServiceTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
    @tablesetting = tablesettings(:one)
    # Ensure tablesetting belongs to restaurant one
    @tablesetting.update!(restaurant: @restaurant)
  end

  test 'broadcast_tile does nothing when tablesetting not found' do
    broadcasts = []
    ActionCable.server.stub :broadcast, ->(stream, data) { broadcasts << data } do
      FloorplanBroadcastService.broadcast_tile(
        tablesetting_id: 999_999,
        restaurant_id: @restaurant.id,
      )
    end
    assert_empty broadcasts
  end

  test 'broadcast_tile sends event to correct stream' do
    broadcast_stream = nil
    broadcast_data = nil

    ActionCable.server.stub :broadcast, lambda { |stream, data|
      broadcast_stream = stream
      broadcast_data = data
    } do
      FloorplanBroadcastService.broadcast_tile(
        tablesetting_id: @tablesetting.id,
        restaurant_id: @restaurant.id,
      )
    end

    assert_equal "floorplan:restaurant:#{@restaurant.id}", broadcast_stream
    assert_equal 'tile_update', broadcast_data[:type]
    assert_equal @tablesetting.id, broadcast_data[:tablesetting_id]
    assert broadcast_data[:html].present?
  end

  test 'broadcast_tile includes available tile html when no active order' do
    # Ensure no active orders for this tablesetting
    @tablesetting.ordrs.update_all(status: Ordr.statuses[:closed])

    broadcast_data = nil
    ActionCable.server.stub :broadcast, ->(_stream, data) { broadcast_data = data } do
      FloorplanBroadcastService.broadcast_tile(
        tablesetting_id: @tablesetting.id,
        restaurant_id: @restaurant.id,
      )
    end

    assert_includes broadcast_data[:html], 'Available'
  end

  test 'broadcast_tile does not raise on render error — logs warning instead' do
    # Force a render error by pointing to non-existent partial via monkey-patch
    ApplicationController.method(:renderer)
    bad_renderer = Object.new
    bad_renderer.define_singleton_method(:render) { |**_kwargs| raise 'render exploded' }

    ApplicationController.stub :renderer, bad_renderer do
      assert_nothing_raised do
        FloorplanBroadcastService.broadcast_tile(
          tablesetting_id: @tablesetting.id,
          restaurant_id: @restaurant.id,
        )
      end
    end
  end
end
