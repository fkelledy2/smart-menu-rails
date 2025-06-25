class UserChannel < ApplicationCable::Channel
  def subscribed
    session_id = params[:session_id]
    stream_from "user_#{session_id}_channel"
  end
  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
