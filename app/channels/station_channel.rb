class StationChannel < ApplicationCable::Channel
  def subscribed
    restaurant_id = params[:restaurant_id]
    station = params[:station]
    return reject unless restaurant_id && station

    unless %w[kitchen bar].include?(station)
      return reject
    end

    stream_from "#{station}_#{restaurant_id}"

    return unless current_user

    PresenceService.user_online(
      current_user,
      connection.connection_identifier,
      resource_type: 'Restaurant',
      resource_id: restaurant_id,
    )
  end

  def unsubscribed
    return unless current_user

    PresenceService.user_offline(
      current_user,
      connection.connection_identifier,
    )
  end
end
