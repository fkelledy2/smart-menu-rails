class UserChannel < ApplicationCable::Channel
  def subscribed
    return reject unless current_user

    stream_from "user_#{current_user.id}_channel"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
