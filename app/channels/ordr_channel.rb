class OrdrChannel < ApplicationCable::Channel
  def subscribed
    # Support subscribing by order_id (numeric) or by smartmenu slug (string)
    identifier = params[:order_id].presence || params[:slug].presence
    return unless identifier.present?

    stream_from "ordr_#{identifier}_channel"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
