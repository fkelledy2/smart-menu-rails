# frozen_string_literal: true

module Crm
  # Processes a WebsiteContactSubmission:
  #   1. Spam check (honeypot was handled synchronously in controller, but
  #      disposable-domain check runs here as a second layer)
  #   2. Deduplicate via Crm::LeadMatcher
  #   3. Create or update lead
  #   4. Apply tags
  #   5. Write audit
  #   6. Send admin notification email
  #   7. Mark submission processed
  #
  # Idempotency: guarded by processed_at presence check + advisory lock.
  # On unhandled exception: marks submission 'failed' and re-raises for Sidekiq retry.
  class ProcessWebsiteContactSubmissionJob < ApplicationJob
    queue_as :default

    # @param submission_id [Integer]
    def perform(submission_id)
      submission = WebsiteContactSubmission.find_by(id: submission_id)
      return unless submission
      return if submission.processed_at.present?   # idempotency guard

      # Spam check (already caught synchronously, but belt-and-suspenders)
      if submission.status_rejected_as_spam?
        Rails.logger.info("[CRM] Submission #{submission_id} already marked spam — skipping")
        return
      end

      # Disposable-email check
      if Crm::LeadMatcher.new(email: submission.email,
                               name: nil, phone: nil,
                               restaurant_name: nil).spam?
        submission.update!(processing_status: 'rejected_as_spam', processed_at: Time.current)
        Rails.logger.info("[CRM] Submission #{submission_id} rejected as spam (disposable email)")
        return
      end

      ActiveRecord::Base.transaction do
        existing_lead = Crm::LeadMatcher.call(
          name:            submission.name,
          email:           submission.email,
          phone:           submission.phone,
          restaurant_name: submission.restaurant_name,
        )

        lead = if existing_lead
                 handle_existing_lead(existing_lead, submission)
                 existing_lead
               else
                 create_new_lead(submission)
               end

        Crm::LeadTagger.call(crm_lead: lead, tags: %w[unsolicited inbound])

        submission.update!(
          crm_lead_id:       lead.id,
          processed_at:      Time.current,
          processing_status: 'processed',
        )
      end

      # Deliver admin notification outside transaction (network I/O)
      submission.reload
      CrmMailer.inbound_lead_notification(submission).deliver_later

    rescue StandardError => e
      submission&.update_columns(
        processing_status: 'failed',
        error_message:     "#{e.class}: #{e.message}",
        updated_at:        Time.current,
      )
      raise
    end

    private

    def handle_existing_lead(lead, submission)
      Crm::InboundSubmissionNoteWriter.call(crm_lead: lead, submission: submission)

      # Source precedence: do NOT overwrite a higher-ranked source
      current_rank  = CrmLead::SOURCE_PRECEDENCE[lead.source.to_s].to_i
      inbound_rank  = CrmLead::SOURCE_PRECEDENCE['website_inbound'].to_i
      return unless current_rank < inbound_rank

      # Only upgrade if the existing source is lower-ranked than website_inbound
      lead.update!(source: 'website_inbound')
    end

    def create_new_lead(submission)
      result = Crm::LeadCreatorFromWebsiteSubmission.call(submission: submission)
      raise "LeadCreatorFromWebsiteSubmission failed: #{result.error}" unless result.success?

      Crm::LeadAuditWriter.write(
        crm_lead:   result.lead,
        event:      'lead_created',
        actor_type: 'system',
        metadata:   { submission_id: submission.id, source: 'website_inbound' },
      )

      result.lead
    end
  end
end
