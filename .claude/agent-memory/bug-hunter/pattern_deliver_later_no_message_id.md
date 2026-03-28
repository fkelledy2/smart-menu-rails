---
name: deliver_later returns job handle not Mail::Message
description: ActionMailer deliver_later returns ActionMailer::MessageDelivery (job proxy), not Mail::Message — message_id is not accessible after the call
type: project
---

`CrmMailer.lead_follow_up(email_send).deliver_later` returns an `ActionMailer::MessageDelivery` proxy object. Calling `.message_id` on it fails silently (returns nil or raises NoMethodError depending on Rails version). `mailer_message_id` was never stored in `CrmEmailSend` as a result.

**Fix:** Generate the `message_id` as a random hex string before calling the mailer, persist it on the `CrmEmailSend` record, then pass it to the mailer via `email_send.mailer_message_id`. The mailer reads the pre-assigned value instead of generating its own.

**Why:** `deliver_later` enqueues a Sidekiq job and returns immediately — the mail is not built until the job runs, so the message_id is not available at enqueue time.

**How to apply:** Any time code tries to capture metadata from `deliver_later`'s return value, generate that metadata before the call and pass it through the record.
