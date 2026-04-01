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

  def receive(data)
    case data['action']
    when 'advance_station'
      handle_station_advance(data)
    end
  end

  private

  def handle_station_advance(data)
    return unless current_user

    ordr_id     = data['ordr_id'].to_i
    station     = data['station'].to_s
    from_status = data['from_status'].to_s
    to_status   = data['to_status'].to_s

    ordr = Ordr.find_by(id: ordr_id)
    return unless ordr

    # Verify the authenticated user belongs to this order's restaurant
    owns     = current_user.restaurants.exists?(id: ordr.restaurant_id)
    works_at = current_user.employees.exists?(restaurant_id: ordr.restaurant_id)
    return unless owns || works_at || current_user.super_admin?

    result = Ordritems::TransitionGroup.new(
      ordr_id: ordr_id,
      station: station,
      from_status: from_status,
      to_status: to_status,
      actor: current_user,
    ).call

    transmit({ action: 'station_advance_result', result: result })
  end
end
