# frozen_string_literal: true

class DemoBooking < ApplicationRecord
  RESTAURANT_TYPES = %w[
    casual_dining
    fine_dining
    quick_service
    cafe_bakery
    bar_nightclub
    hotel_resort
    catering
    food_truck
    other
  ].freeze

  CONVERSION_STATUSES = %w[pending contacted booked converted lost].freeze

  LOCATION_COUNTS = %w[1 2-5 6-10 11-25 26+].freeze

  validates :restaurant_name, presence: true, length: { maximum: 255 }
  validates :contact_name,    presence: true, length: { maximum: 255 }
  validates :email,           presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }, length: { maximum: 255 }
  validates :phone,           length: { maximum: 50 }, allow_blank: true
  validates :restaurant_type, inclusion: { in: RESTAURANT_TYPES }, allow_blank: true
  validates :location_count,  inclusion: { in: LOCATION_COUNTS }, allow_blank: true
  validates :conversion_status, inclusion: { in: CONVERSION_STATUSES }
  validates :interests, length: { maximum: 2000 }, allow_blank: true

  scope :pending,    -> { where(conversion_status: 'pending') }
  scope :recent,     -> { order(created_at: :desc) }
  scope :by_email,   ->(email) { where(email: email.to_s.downcase.strip) }

  before_validation :normalise_email

  # Build a Calendly pre-fill URL for this lead.
  # Falls back gracefully if CALENDLY_EVENT_URL is not configured.
  def calendly_booking_url
    base = ENV.fetch('CALENDLY_EVENT_URL', 'https://calendly.com/mellow-menu/demo')
    params = {
      name: contact_name,
      email: email,
      a1: restaurant_name,
    }.compact

    uri = URI.parse(base)
    existing = URI.decode_www_form(uri.query.to_s).to_h
    uri.query = URI.encode_www_form(existing.merge(params))
    uri.to_s
  rescue URI::InvalidURIError
    'https://calendly.com/mellow-menu/demo'
  end

  private

  def normalise_email
    self.email = email.to_s.downcase.strip if email.present?
  end
end
