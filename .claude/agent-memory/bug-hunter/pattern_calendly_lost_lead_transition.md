---
name: Calendly lost-lead transition failure
description: CalendlyEventHandler's past_stages guard omitted 'lost', causing webhook failures for leads in lost stage (Calendly retries indefinitely)
type: project
---

`Crm::CalendlyEventHandler` had `past_stages = %w[demo_booked demo_completed proposal_sent trial_active converted]` — missing `'lost'`. A Calendly booking from a lost-lead email triggered `LeadTransitionService.call(new_stage: 'demo_booked')` on a lost lead, which fails (FORWARD_TRANSITIONS['lost'] only allows 'contacted'). The handler returned `success?: false`, causing Calendly to retry the webhook indefinitely.

**Fix:** Add `'lost'` to `past_stages` in `app/services/crm/calendly_event_handler.rb`. A lost lead's stage is not changed by an inbound Calendly webhook — a human must explicitly reopen it.

**Why:** Lost is a terminal state that requires human judgement to exit. Auto-reopening via Calendly would bypass the lost_reason requirement and audit trail.

**How to apply:** When guarding against invalid Calendly transitions, treat `lost` the same as `converted` — both are terminal states that should not be auto-advanced.
