# frozen_string_literal: true

module Crm
  # Sends a CRM follow-up email via Crm::LeadEmailSender.
  # Enqueued by Admin::Crm::EmailSendsController#create.
  # Retries 3 times before dead-lettering.
  class SendLeadEmailJob < ApplicationJob
    queue_as :mailers

    sidekiq_options retry: 3

    def perform(crm_lead_id:, sender_id:, to_email:, subject:, body_html:, body_text: nil)
      lead   = CrmLead.find(crm_lead_id)
      sender = User.find(sender_id)

      Crm::LeadEmailSender.call(
        crm_lead: lead,
        sender: sender,
        to_email: to_email,
        subject: subject,
        body_html: body_html,
        body_text: body_text,
      )
    end
  end
end
