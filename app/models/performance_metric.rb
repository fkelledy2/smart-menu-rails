class PerformanceMetric < ApplicationRecord
  belongs_to :user, optional: true

  validates :endpoint, presence: true
  validates :response_time, presence: true, numericality: { greater_than: 0 }
  validates :status_code, presence: true, inclusion: { in: 100..599 }
  validates :timestamp, presence: true

  scope :recent, ->(timeframe) { where('timestamp > ?', timeframe.ago) }
  scope :slow, ->(threshold = 1000) { where('response_time > ?', threshold) }
  scope :errors, -> { where('status_code >= 400') }
  scope :by_endpoint, ->(endpoint) { where(endpoint: endpoint) }
  scope :by_controller, ->(controller) { where(controller: controller) }

  # Calculate average response time for a timeframe
  def self.avg_response_time(timeframe)
    recent(timeframe).average(:response_time) || 0
  end

  # Calculate error rate for a timeframe
  def self.error_rate(timeframe)
    total = recent(timeframe).count
    return 0 if total.zero?

    error_count = recent(timeframe).errors.count
    (error_count.to_f / total * 100).round(2)
  end

  # Get slowest endpoints
  def self.slowest_endpoints(limit = 10, timeframe = 1.hour)
    recent(timeframe)
      .group(:endpoint)
      .average(:response_time)
      .sort_by { |_, avg_time| -avg_time }
      .first(limit)
  end

  # Group metrics by time intervals for trending
  def self.group_by_time(timeframe, interval = 5.minutes)
    recent(timeframe)
      .group_by { |metric| metric.timestamp.beginning_of_hour + ((metric.timestamp.min / interval.in_minutes).floor * interval) }
      .transform_values { |metrics| metrics.sum(&:response_time) / metrics.count.to_f }
  end
end
