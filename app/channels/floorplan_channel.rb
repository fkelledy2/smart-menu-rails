# frozen_string_literal: true

# FloorplanChannel: staff subscribe to receive real-time table tile updates.
# Stream: "floorplan:restaurant:#{restaurant_id}"
# Broadcast format: { tablesetting_id:, html: <rendered partial> }
class FloorplanChannel < ApplicationCable::Channel
  def subscribed
    restaurant_id = params[:restaurant_id]
    return reject if restaurant_id.blank?

    stream_from "floorplan:restaurant:#{restaurant_id}"
  end

  def unsubscribed
    # No cleanup needed — streams are stateless
  end
end
