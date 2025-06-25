class OrdrChannel < ApplicationCable::Channel
  def subscribed
    order_id = params[:order_id]
    stream_from "ordr_#{order_id}_channel"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
