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
  after_create :create_or_advance_crm_lead

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

  def create_or_advance_crm_lead
    lead = CrmLead.where('LOWER(contact_email) = ?', email.downcase).first

    if lead
      past_stages = %w[demo_booked demo_completed proposal_sent trial_active converted lost]
      unless past_stages.include?(lead.stage)
        Crm::LeadTransitionService.call(lead: lead, new_stage: 'demo_booked', actor: nil)
      end
    else
      lead = CrmLead.create!(
        restaurant_name: restaurant_name,
        contact_name: contact_name,
        contact_email: email,
        contact_phone: phone.presence,
        source: 'website',
        stage: 'demo_booked',
        last_activity_at: Time.current,
      )
      Crm::LeadAuditWriter.write(
        crm_lead: lead,
        event: 'lead_created',
        actor: nil,
        actor_type: 'system',
        metadata: { source: 'demo_booking', demo_booking_id: id },
      )
    end
  end

  def normalise_email
    self.email = email.to_s.downcase.strip if email.present?
  end
end
