# frozen_string_literal: true

class CrmLead < ApplicationRecord
  # -------------------------------------------------------------------------
  # Associations
  # -------------------------------------------------------------------------
  belongs_to :assigned_to, class_name: 'User', optional: true
  belongs_to :restaurant, optional: true
  has_many :crm_lead_notes, dependent: :destroy
  # delete_all bypasses the ImmutableRecordError before_destroy callback on CrmLeadAudit
  has_many :crm_lead_audits, dependent: :delete_all
  has_many :crm_email_sends, dependent: :destroy

  # -------------------------------------------------------------------------
  # Enums
  # -------------------------------------------------------------------------
  STAGES = %w[
    new
    contacted
    demo_booked
    demo_completed
    proposal_sent
    trial_active
    converted
    lost
  ].freeze

  LOST_REASONS = %w[
    price
    competitor
    no_response
    not_a_fit
    timing
    other
  ].freeze

  # prefix: :stage avoids method-name collision with ActiveRecord's #new? and
  # Ruby's inherited Object#new. Predicates become stage_lost?, stage_converted?, etc.
  enum :stage, STAGES.index_by(&:itself), prefix: :stage

  validates :restaurant_name, presence: true
  validates :stage, presence: true, inclusion: { in: STAGES }
  validates :lost_reason, presence: true, if: :stage_lost?
  validates :lost_reason, inclusion: { in: LOST_REASONS }, allow_nil: true
  validates :restaurant_id, presence: { message: 'must be linked before converting' }, if: :stage_converted?

  # -------------------------------------------------------------------------
  # Scopes
  # -------------------------------------------------------------------------
  scope :recent, -> { order(last_activity_at: :desc, created_at: :desc) }
  scope :by_stage, ->(stage) { where(stage: stage) }
  scope :unassigned, -> { where(assigned_to_id: nil) }
  scope :needs_assignment, -> { where(stage: 'demo_booked', assigned_to_id: nil) }

  # -------------------------------------------------------------------------
  # Callbacks
  # -------------------------------------------------------------------------
  before_create :set_initial_last_activity_at

  private

  def set_initial_last_activity_at
    self.last_activity_at ||= Time.current
  end
end
