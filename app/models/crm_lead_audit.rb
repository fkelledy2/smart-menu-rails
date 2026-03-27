# frozen_string_literal: true

class CrmLeadAudit < ApplicationRecord
  # Audit records are immutable — no updated_at column; prevent accidental writes.
  self.ignored_columns += %w[]

  belongs_to :crm_lead
  belongs_to :actor, class_name: 'User', optional: true

  ACTOR_TYPES = %w[user system].freeze
  EVENTS = %w[
    stage_changed
    field_updated
    email_sent
    note_added
    note_deleted
    lead_created
    lead_converted
    lead_reopened
  ].freeze

  validates :event, presence: true
  validates :actor_type, inclusion: { in: ACTOR_TYPES }

  class ImmutableRecordError < StandardError; end

  # Immutability guards at application layer
  before_update { raise ImmutableRecordError, 'CrmLeadAudit records are immutable' }
  before_destroy { raise ImmutableRecordError, 'CrmLeadAudit records cannot be deleted' }
end
