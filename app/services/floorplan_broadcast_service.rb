# frozen_string_literal: true

# Broadcasts real-time table tile updates to the floorplan dashboard.
# Renders the _table_tile partial server-side and sends the HTML + metadata
# as a JSON payload via ActionCable to all staff subscribed on FloorplanChannel.
#
# The Stimulus floorplan_controller.js receives { type: 'tile_update', tablesetting_id:, html: }
# and replaces the matching tile DOM node.
class FloorplanBroadcastService
  class << self
    # Called after an Ordr status change or Ordrparticipant mutation.
    def broadcast_tile(tablesetting_id:, restaurant_id:)
      tablesetting = Tablesetting.find_by(id: tablesetting_id)
      return unless tablesetting

      active_ordr = active_ordr_for(tablesetting)

      html = ApplicationController.renderer.render(
        partial: 'floorplans/table_tile',
        locals: {
          tablesetting: tablesetting,
          ordr: active_ordr,
        },
      )

      ActionCable.server.broadcast(
        "floorplan:restaurant:#{restaurant_id}",
        {
          type: 'tile_update',
          tablesetting_id: tablesetting_id,
          html: html,
        },
      )
    rescue StandardError => e
      Rails.logger.warn(
        "[FloorplanBroadcastService] broadcast_tile failed for tablesetting_id=#{tablesetting_id}: #{e.class}: #{e.message}",
      )
    end

    private

    def active_ordr_for(tablesetting)
      tablesetting
        .ordrs
        .where.not(status: %w[paid closed])
        .order(created_at: :desc)
        .first
    end
  end
end
