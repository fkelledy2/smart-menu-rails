# frozen_string_literal: true

module Crm
  # Appends a system-authored CrmLeadNote to an existing lead when a new
  # website contact submission matches that lead (deduplication hit).
  # Also writes a CrmLeadAudit with event 'inbound_submission_matched'.
  class InboundSubmissionNoteWriter
    # @param crm_lead [CrmLead]
    # @param submission [WebsiteContactSubmission]
    # @return [CrmLeadNote]
    def self.call(crm_lead:, submission:)
      new(crm_lead: crm_lead, submission: submission).call
    end

    def initialize(crm_lead:, submission:)
      @crm_lead   = crm_lead
      @submission = submission
    end

    def call
      note = @crm_lead.crm_lead_notes.create!(
        body:              build_note_body,
        created_by_system: true,
      )

      Crm::LeadAuditWriter.write(
        crm_lead:   @crm_lead,
        event:      'inbound_submission_matched',
        actor_type: 'system',
        metadata:   { submission_id: @submission.id },
      )

      note
    end

    private

    def build_note_body
      lines = []
      lines << 'New website contact form submission received (matched to this lead).'
      lines << ''
      lines << "Name: #{@submission.name}" if @submission.name.present?
      lines << "Email: #{@submission.email}" if @submission.email.present?
      lines << "Phone: #{@submission.phone}" if @submission.phone.present?
      lines << "Company: #{@submission.company_name}" if @submission.company_name.present?
      lines << "Restaurant: #{@submission.restaurant_name}" if @submission.restaurant_name.present?
      lines << ''
      lines << "Message:\n#{@submission.message}"
      lines.join("\n")
    end
  end
end
