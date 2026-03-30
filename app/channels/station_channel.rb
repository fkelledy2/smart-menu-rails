class StationChannel < ApplicationCable::Channel
  def subscribed
    restaurant_id = params[:restaurant_id]
    station = params[:station]
    return reject unless restaurant_id && station
    return reject unless current_user

    unless %w[kitchen bar].include?(station)
      return reject
    end

    # Only restaurant owners and their employees may monitor kitchen/bar streams.
    owns = current_user.restaurants.exists?(id: restaurant_id)
    works_at = current_user.employees.exists?(restaurant_id: restaurant_id)
    return reject unless owns || works_at

    stream_from "#{station}_#{restaurant_id}"

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
