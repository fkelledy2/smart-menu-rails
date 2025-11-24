class AlcoholPolicy < ApplicationRecord
  belongs_to :restaurant

  # allowed_days_of_week: array of integers 0..6 (0=Sunday)
  # allowed_time_ranges: array of hashes [{"from_min"=>690, "to_min"=>1380}, ...]
  # blackout_dates: array of Date

  validate :validate_days
  validate :validate_time_ranges

  def allowed_now?(now: Time.zone.now)
    return true if allowed_days_of_week.blank? && allowed_time_ranges.blank? && blackout_dates.blank?

    # Blackout date check (date in restaurant TZ)
    today = now.to_date
    return false if blackout_dates&.include?(today)

    # Day-of-week check
    if allowed_days_of_week.present?
      wday = now.wday # 0..6
      return false unless allowed_days_of_week.include?(wday)
    end

    # Time range check (minutes since midnight)
    if allowed_time_ranges.present?
      minutes = now.hour * 60 + now.min
      in_any_range = allowed_time_ranges.any? do |r|
        from_min = r["from_min"].to_i
        to_min = r["to_min"].to_i
        from_min <= minutes && minutes <= to_min
      end
      return false unless in_any_range
    end

    true
  end

  private

  def validate_days
    return if allowed_days_of_week.blank?
    unless allowed_days_of_week.all? { |d| d.is_a?(Integer) && d.between?(0, 6) }
      errors.add(:allowed_days_of_week, 'must contain integers between 0 and 6 (0=Sunday)')
    end
  end

  def validate_time_ranges
    return if allowed_time_ranges.blank?
    unless allowed_time_ranges.is_a?(Array)
      errors.add(:allowed_time_ranges, 'must be an array of {from_min,to_min}')
      return
    end
    allowed_time_ranges.each do |r|
      unless r.is_a?(Hash) && r.key?("from_min") && r.key?("to_min")
        errors.add(:allowed_time_ranges, 'each range must include from_min and to_min')
        next
      end
      from_min = r["from_min"].to_i
      to_min = r["to_min"].to_i
      if from_min < 0 || to_min > 24 * 60 || from_min > to_min
        errors.add(:allowed_time_ranges, 'invalid minute bounds or from_min > to_min')
      end
    end
  end
end
