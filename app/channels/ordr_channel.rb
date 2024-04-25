class OrdrChannel < ApplicationCable::Channel
  def subscribed
    stream_from "ordr_channel"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
