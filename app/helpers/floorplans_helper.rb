# frozen_string_literal: true

module FloorplansHelper
  PREPARING_DELAY_MINUTES = 15
  BILLREQUESTED_DELAY_MINUTES = 5

  # Returns the Bootstrap badge class for a given Ordr status string.
  def floorplan_status_badge_class(status)
    case status.to_s
    when 'opened'       then 'bg-secondary'
    when 'ordered'      then 'bg-primary'
    when 'preparing'    then 'bg-warning text-dark'
    when 'ready'        then 'bg-success'
    when 'delivered'    then 'bg-success bg-opacity-50'
    when 'billrequested' then 'bg-purple text-white'
    when 'paid', 'closed' then 'bg-light text-muted'
    else 'bg-secondary'
    end
  end

  # Returns a human-readable label for the status chip.
  def floorplan_status_label(status)
    {
      'opened' => 'Opened',
      'ordered' => 'Ordered',
      'preparing' => 'Preparing',
      'ready' => 'Ready',
      'delivered' => 'Delivered',
      'billrequested' => 'Bill Requested',
      'paid' => 'Paid',
      'closed' => 'Closed',
    }.fetch(status.to_s, status.to_s.humanize)
  end

  # Returns a human-readable elapsed time label, e.g. "12 min ago"
  def floorplan_elapsed_label(created_at)
    return 'unknown' unless created_at

    minutes = ((Time.current - created_at) / 60).to_i
    if minutes < 1
      'just now'
    elsif minutes == 1
      '1 min'
    elsif minutes < 60
      "#{minutes} min"
    else
      hours = minutes / 60
      "#{hours}h #{minutes % 60}m"
    end
  end

  # Returns true if the table should be highlighted as delayed.
  # Applies to: preparing/ready orders open > 15 min, billrequested > 5 min.
  def floorplan_tile_delayed?(ordr)
    return false unless ordr

    minutes_elapsed = ((Time.current - ordr.created_at) / 60).to_i
    case ordr.status.to_s
    when 'preparing', 'ready'
      minutes_elapsed > PREPARING_DELAY_MINUTES
    when 'billrequested'
      minutes_elapsed > BILLREQUESTED_DELAY_MINUTES
    else
      false
    end
  end
end
