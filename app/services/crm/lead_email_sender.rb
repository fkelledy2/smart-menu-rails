# frozen_string_literal: true

module Crm
  # Builds and dispatches the CrmMailer, persists a CrmEmailSend record,
  # and writes a CrmLeadAudit entry.
  class LeadEmailSender
    Result = Struct.new(:success?, :email_send, :error, keyword_init: true)

    def self.call(crm_lead:, sender:, to_email:, subject:, body_html:, body_text: nil)
      new(
        crm_lead: crm_lead,
        sender: sender,
        to_email: to_email,
        subject: subject,
        body_html: body_html,
        body_text: body_text,
      ).call
    end

    def initialize(crm_lead:, sender:, to_email:, subject:, body_html:, body_text:)
      @crm_lead  = crm_lead
      @sender    = sender
      @to_email  = to_email
      @subject   = subject
      @body_html = body_html
      @body_text = body_text
    end

    def call
      email_send = CrmEmailSend.create!(
        crm_lead: @crm_lead,
        sender: @sender,
        to_email: @to_email,
        subject: @subject,
        body_html: @body_html,
        body_text: @body_text,
        sent_at: Time.current,
      )

      message = CrmMailer.lead_follow_up(email_send).deliver_later
      email_send.update_column(:mailer_message_id, message.message_id) if message.respond_to?(:message_id)

      @crm_lead.touch(:last_activity_at)

      Crm::LeadAuditWriter.write(
        crm_lead: @crm_lead,
        event: 'email_sent',
        actor: @sender,
        metadata: {
          to_email: @to_email,
          subject: @subject,
          email_send_id: email_send.id,
        },
      )

      Result.new(success?: true, email_send: email_send, error: nil)
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success?: false, email_send: nil, error: e.message)
    rescue StandardError => e
      Rails.logger.error("[Crm::LeadEmailSender] Error: #{e.message}")
      Result.new(success?: false, email_send: nil, error: e.message)
    end
  end
end
