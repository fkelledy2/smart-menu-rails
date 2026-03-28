---
name: Crm::SendLeadEmailJob not idempotent — duplicate emails on retry
description: SendLeadEmailJob delegates to LeadEmailSender which creates CrmEmailSend then deliver_later. If the job crashes between create! and deliver_later, retry creates a second CrmEmailSend and sends a duplicate email.
type: project
---

`Crm::LeadEmailSender#call` (`app/services/crm/lead_email_sender.rb`) does:
1. `CrmEmailSend.create!` — saves the record
2. `CrmMailer.lead_follow_up(email_send).deliver_later` — enqueues the mail
3. `email_send.update_column(:mailer_message_id, ...)` — updates record
4. `@crm_lead.touch(:last_activity_at)` + audit write

`Crm::SendLeadEmailJob` has `sidekiq_options retry: 3`. If a transient error (Redis timeout, DB blip) occurs after step 1 but before step 2 completes and the job acknowledges, Sidekiq will retry from the top. A second `CrmEmailSend` is created and a duplicate email is sent. There is no idempotency key or dedup check.

**Why:** The job was not designed with retry safety in mind; the service is a simple linear sequence.

**How to apply:** Add an idempotency key to `CrmEmailSend` (e.g., composite unique index on `crm_lead_id + subject + to_email + Date.current`), or pass a `job_idempotency_key` from the job into the service and check for an existing send before creating.
