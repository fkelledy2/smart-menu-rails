# frozen_string_literal: true

# Immutable raw artifact capturing every homepage contact form submission.
# Created synchronously in the controller before the processing job is enqueued.
# Only the processing-state columns (processing_status, processed_at, error_message,
# lead_id) may be mutated after initial creation.
class WebsiteContactSubmission < ApplicationRecord
  PROCESSING_STATUSES = %w[pending processed rejected_as_spam failed].freeze

  # Mutable columns — updated by the background job or spam detection
  MUTABLE_COLUMNS = %w[
    processing_status
    processed_at
    error_message
    crm_lead_id
    updated_at
  ].freeze

  belongs_to :crm_lead, optional: true

  enum :processing_status, PROCESSING_STATUSES.index_by(&:itself),
       prefix: :status

  validates :name,               presence: true
  validates :email,              presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :message,            presence: true
  validates :submitted_at,       presence: true
  validates :processing_status,  inclusion: { in: PROCESSING_STATUSES }

  # Scope helpers
  scope :pending,          -> { where(processing_status: 'pending') }
  scope :failed,           -> { where(processing_status: 'failed') }
  scope :rejected_as_spam, -> { where(processing_status: 'rejected_as_spam') }

  # Immutability guard — only allow writes to processing-state columns after initial save
  before_update :guard_immutable_columns

  private

  def guard_immutable_columns
    changed_attrs = changed - MUTABLE_COLUMNS
    return if changed_attrs.empty?

    raise ActiveRecord::ReadOnlyRecord,
          "WebsiteContactSubmission fields #{changed_attrs.join(', ')} are immutable"
  end
end
