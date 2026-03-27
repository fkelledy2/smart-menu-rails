# frozen_string_literal: true

class CrmMailer < ApplicationMailer
  # Sends a follow-up email to a CRM lead.
  # Subject and body are provided by the sales rep at compose time.
  def lead_follow_up(crm_email_send)
    @crm_email_send = crm_email_send
    @crm_lead = crm_email_send.crm_lead
    @sender = crm_email_send.sender

    mail(
      to: crm_email_send.to_email,
      subject: crm_email_send.subject,
      message_id: "<crm-#{crm_email_send.id}-#{SecureRandom.hex(8)}@mellow.menu>",
    )
  end
end
