# frozen_string_literal: true

module Crm
  # Single-responsibility service for writing CrmLeadAudit records.
  # All audit writes must flow through here — never write CrmLeadAudit directly.
  class LeadAuditWriter
    # @param crm_lead [CrmLead]
    # @param event [String] one of CrmLeadAudit::EVENTS
    # @param actor [User, nil] nil for system-triggered events
    # @param actor_type [String] 'user' or 'system'
    # @param field_name [String, nil]
    # @param from_value [Object, nil]
    # @param to_value [Object, nil]
    # @param metadata [Hash]
    # @return [CrmLeadAudit]
    def self.write(
      crm_lead:,
      event:,
      actor: nil,
      actor_type: actor ? 'user' : 'system',
      field_name: nil,
      from_value: nil,
      to_value: nil,
      metadata: {}
    )
      CrmLeadAudit.create!(
        crm_lead: crm_lead,
        actor: actor,
        actor_type: actor_type,
        event: event,
        field_name: field_name,
        from_value: from_value&.to_s,
        to_value: to_value&.to_s,
        metadata: metadata,
        created_at: Time.current,
      )
    end
  end
end
