# frozen_string_literal: true

# Stores historical dining duration patterns per restaurant, aggregated by
# party size, day of week, and hour of day.
# Updated nightly by UpdateDiningPatternsJob.
class DiningPattern < ApplicationRecord
  belongs_to :restaurant

  validates :party_size, presence: true,
                         numericality: { only_integer: true, greater_than: 0 }
  validates :day_of_week, presence: true,
                          numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 6 }
  validates :hour_of_day, presence: true,
                          numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 23 }
  validates :average_duration_minutes, presence: true,
                                       numericality: { greater_than: 0 }
  validates :median_duration_minutes, presence: true,
                                      numericality: { greater_than: 0 }
  validates :sample_count, presence: true,
                           numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :last_calculated_at, presence: true

  validates :restaurant_id, uniqueness: {
    scope: %i[party_size day_of_week hour_of_day],
    message: 'already has a pattern for this party size, day, and hour',
  }

  scope :for_party_size, ->(size) { where(party_size: size) }
  scope :for_day_and_hour, ->(day, hour) { where(day_of_week: day, hour_of_day: hour) }
  scope :sufficient_data, -> { where(sample_count: 5..) }
end
