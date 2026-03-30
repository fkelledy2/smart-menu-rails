# Feature Spec: CRM Sales Funnel

**Status**: Backlog
**Created**: 2026-03-27
**Author**: Feature Backlog Agent
**Flipper Flag**: `crm_sales_funnel`

---

## Overview

An internal CRM tool for the mellow.menu sales team to manage the restaurant acquisition pipeline. Leads move through a fixed, opinionated set of funnel stages (from initial contact through to converted customer) via a Kanban board with drag-and-drop stage transitions. Automatic stage progressions are triggered by external events (e.g. Calendly demo bookings via webhook). Converted leads link directly to their `Restaurant` record. Sales reps can send follow-up emails and log notes from within the CRM UI. Every field change is captured in a full audit trail.

---

## Goals

- [ ] Give the sales team a single internal workspace to track every restaurant prospect from first contact to conversion
- [ ] Reduce manual status updates by automatically advancing leads when key events fire (demo booked, trial activated)
- [ ] Ensure converted leads are traceable to their live `Restaurant` record for post-conversion reporting
- [ ] Provide a complete, tamper-evident audit trail of all field changes and team activity for accountability
- [ ] Enable follow-up emails to be composed and sent directly from the CRM without context-switching to a separate email client

---

## Non-Goals (Out of Scope for v1)

- Public-facing lead capture forms (leads are created manually by the sales team or via webhook only)
- Email inbox / two-way email threading (outbound send only; replies are not tracked in v1)
- Automated email sequences / drip campaigns
- Mobile native app view (responsive web is sufficient)
- Lead scoring or ML-based prioritisation
- Integration with external CRM platforms (HubSpot, Salesforce)
- Revenue forecasting or pipeline value reporting
- Contact deduplication engine
- Bulk import of leads from CSV

---

## User Stories

**As a sales rep**, I want to see all my leads on a Kanban board grouped by stage so that I can quickly assess pipeline health and prioritise my day.

**As a sales rep**, I want to drag a lead card from one stage column to another so that I can update its status without leaving the board.

**As a sales rep**, I want to open a lead detail panel and write an internal note so that I can record context from a call for myself and my teammates.

**As a sales rep**, I want to send a follow-up email to a lead directly from the CRM so that I do not have to context-switch to my email client and lose the conversation thread.

**As a sales manager**, I want to see a full activity log on every lead showing who changed what and when so that I can coach my team and identify stalled deals.

**As a sales manager**, I want to receive an automatic stage transition when a prospect books a demo via Calendly so that the board reflects reality without requiring manual updates.

**As a sales rep**, I want to mark a lead as converted and link it to the corresponding `Restaurant` record so that the sales and product teams can trace the onboarding journey.

**As a mellow.menu platform admin**, I want all CRM data to be accessible only to admin-role users so that restaurant owners and customers can never view or interact with sales pipeline data.

---

## Technical Design

### Architecture Notes

The CRM is an admin-only feature living entirely within the `admin/` namespace. No restaurant-tenant scoping is required — this is platform-level data belonging to mellow.menu itself, not to any individual `Restaurant`. All CRM models are unscoped from the multi-tenant pattern and query only the primary database.

Lead stage transitions are orchestrated by a dedicated service object layer (`Crm::LeadTransitionService`). Controllers stay thin — they call the service and respond. Drag-and-drop on the Kanban board fires a Turbo Stream PATCH to reorder/transition leads; the controller delegates immediately to the service. No ActionCable is required for v1 (the board is not multi-user realtime; a page-level Turbo visit after transition is sufficient).

Calendly webhook payloads arrive at a dedicated endpoint outside the admin namespace and are verified before processing. The handler enqueues a background job that calls `Crm::LeadTransitionService` to advance the lead to `demo_booked`.

Email sending routes through `ActionMailer` using the existing branded mailer layout (`app/views/layouts/mailer.html.erb`). No new email provider is needed. Sent email records are persisted for the activity log.

The audit trail uses a dedicated `CrmLeadAudit` model rather than a generic paper_trail dependency — this avoids adding a new gem and gives us explicit control over what is captured and how it is queried.

### New Dependencies

No new gems required.

- Drag-and-drop on the Kanban board is implemented with the **Sortable.js** library via a Stimulus controller. Sortable.js is already bundled in this project (`app/javascript/` — confirm with `grep -r 'sortable' app/javascript`). If it is not present, it is an MIT-licensed, zero-dependency JS library with no Rails gem wrapper needed — add directly to `package.json`.
- Calendly webhook verification uses HMAC-SHA256 with a shared secret (stored in Rails credentials). No Calendly SDK is needed — raw `Net::HTTP` is not involved; webhook is inbound only.
- All email sending uses the existing `ActionMailer` + `Sidekiq` stack.

### Data Model Changes

**New models:**

- [ ] `CrmLead` — the core prospect record
  - `id` (bigint PK)
  - `restaurant_name` (string, not null)
  - `contact_name` (string)
  - `contact_email` (string)
  - `contact_phone` (string)
  - `stage` (string, not null, default: `'new'`) — enum, see Stage Reference below
  - `assigned_to_id` (bigint, FK → `users.id`, nullable) — the internal sales rep
  - `restaurant_id` (bigint, FK → `restaurants.id`, nullable) — linked on conversion
  - `source` (string) — e.g. `'manual'`, `'calendly'`, `'referral'`
  - `notes_count` (integer, default: 0) — counter cache
  - `last_activity_at` (datetime) — denormalised for Kanban sort
  - `converted_at` (datetime)
  - `lost_at` (datetime)
  - `lost_reason` (string)
  - `calendly_event_uuid` (string) — for idempotent webhook handling
  - `timestamps`

- [ ] `CrmLeadNote` — internal timestamped notes
  - `id` (bigint PK)
  - `crm_lead_id` (bigint, FK, not null)
  - `author_id` (bigint, FK → `users.id`, not null)
  - `body` (text, not null)
  - `timestamps`

- [ ] `CrmLeadAudit` — immutable field-change audit trail
  - `id` (bigint PK)
  - `crm_lead_id` (bigint, FK, not null)
  - `actor_id` (bigint, FK → `users.id`, nullable) — null when triggered by webhook/job
  - `actor_type` (string, default: `'user'`) — `'user'` | `'system'`
  - `event` (string, not null) — e.g. `'stage_changed'`, `'field_updated'`, `'email_sent'`, `'note_added'`
  - `field_name` (string) — which field changed (nullable for non-field events)
  - `from_value` (text) — serialised previous value
  - `to_value` (text) — serialised new value
  - `metadata` (jsonb) — arbitrary context (e.g. email subject, Calendly event ID)
  - `created_at` (datetime, not null) — no `updated_at`; audit records are immutable

- [ ] `CrmEmailSend` — record of every outbound email sent from the CRM
  - `id` (bigint PK)
  - `crm_lead_id` (bigint, FK, not null)
  - `sender_id` (bigint, FK → `users.id`, not null)
  - `to_email` (string, not null)
  - `subject` (string, not null)
  - `body_html` (text)
  - `body_text` (text)
  - `mailer_message_id` (string) — `ActionMailer` message ID for reference
  - `sent_at` (datetime)
  - `timestamps`

**Migrations:**

- [ ] `create_crm_leads`
- [ ] `create_crm_lead_notes`
- [ ] `create_crm_lead_audits`
- [ ] `create_crm_email_sends`

**Indexes:**

- [ ] `index_crm_leads_on_stage`
- [ ] `index_crm_leads_on_assigned_to_id`
- [ ] `index_crm_leads_on_restaurant_id`
- [ ] `index_crm_leads_on_calendly_event_uuid` (unique, partial: `WHERE calendly_event_uuid IS NOT NULL`)
- [ ] `index_crm_leads_on_last_activity_at`
- [ ] `index_crm_lead_notes_on_crm_lead_id`
- [ ] `index_crm_lead_audits_on_crm_lead_id`
- [ ] `index_crm_lead_audits_on_actor_id`
- [ ] `index_crm_email_sends_on_crm_lead_id`

**Policies:**

- [ ] `CrmLeadPolicy` in `app/policies/` — admin-only for all actions
- [ ] `CrmLeadNotePolicy` — admin-only
- [ ] `CrmEmailSendPolicy` — admin-only

#### Stage Reference (fixed enum)

| Stage | Value | Transition |
|-------|-------|------------|
| New | `new` | Manual (lead created) |
| Contacted | `contacted` | Manual drag or explicit action |
| Demo Booked | `demo_booked` | **Automatic** via Calendly webhook, or manual |
| Demo Completed | `demo_completed` | Manual |
| Proposal Sent | `proposal_sent` | Manual |
| Trial Active | `trial_active` | **Automatic** when `Restaurant` record created and linked, or manual |
| Converted | `converted` | Manual (requires `restaurant_id` to be set) |
| Lost | `lost` | Manual (prompts for `lost_reason`) |

Stage transitions are one-directional (forward) with the single exception that `lost` leads can be re-opened by moving back to `contacted`. All transitions are validated in `Crm::LeadTransitionService`.

---

### Service Objects

- [ ] `app/services/crm/lead_transition_service.rb` — validates and executes stage transitions; writes a `CrmLeadAudit` record for every transition; updates `last_activity_at`; enforces stage-specific preconditions (e.g. `converted` requires `restaurant_id`)
- [ ] `app/services/crm/lead_audit_writer.rb` — single-responsibility service called by any code that needs to write an audit record; all audit writes flow through here (never write `CrmLeadAudit` directly elsewhere)
- [ ] `app/services/crm/calendly_webhook_verifier.rb` — verifies the `Calendly-Webhook-Signature` HMAC-SHA256 header against `Rails.application.credentials.calendly_webhook_secret`; raises `Crm::WebhookVerificationError` on failure
- [ ] `app/services/crm/calendly_event_handler.rb` — parses a verified Calendly webhook payload, looks up the matching `CrmLead` by email, and calls `Crm::LeadTransitionService` to advance to `demo_booked`; if no matching lead exists, auto-creates one with `source: 'calendly'`, `assigned_to_id: nil`, and `stage: 'demo_booked'`; idempotent via `calendly_event_uuid`
- [ ] `app/services/crm/lead_email_sender.rb` — builds and dispatches the `CrmMailer` mailer, persists a `CrmEmailSend` record, and writes a `CrmLeadAudit` entry with `event: 'email_sent'`

---

### Background Jobs

- [ ] `app/jobs/crm/process_calendly_webhook_job.rb`
  - **Trigger**: Enqueued by `Admin::Webhooks::CalendlyController#create` after signature verification passes
  - **Queue**: `crm` (new dedicated queue; low-priority relative to `default`)
  - **Responsibility**: Calls `Crm::CalendlyEventHandler` with the raw verified payload
  - **Retry**: Sidekiq default (25 retries with exponential back-off); idempotent via `calendly_event_uuid`

- [ ] `app/jobs/crm/send_lead_email_job.rb`
  - **Trigger**: Enqueued by `Admin::Crm::EmailSendsController#create`
  - **Queue**: `mailers`
  - **Responsibility**: Calls `Crm::LeadEmailSender` with `crm_lead_id`, `sender_id`, and email params
  - **Retry**: 3 retries; dead-letter on final failure with admin alert

---

### Controllers & Routes

All CRM routes are nested under the existing `admin/` namespace and protected by the existing admin authentication `before_action`.

```
namespace :admin do
  namespace :crm do
    resources :leads do
      member do
        patch :transition   # drag-and-drop stage change
        patch :convert      # link to Restaurant and set converted
        patch :reopen       # lost → contacted
      end
      resources :notes,       only: [:create, :destroy]
      resources :email_sends, only: [:new, :create]
      resources :audits,      only: [:index]
    end
  end

  namespace :webhooks do
    post :calendly, to: 'calendly#create'   # outside admin auth; see Security section
  end
end
```

- [ ] `app/controllers/admin/crm/leads_controller.rb` — index (Kanban data), show, new, create, update, destroy, transition, convert, reopen
- [ ] `app/controllers/admin/crm/notes_controller.rb` — create, destroy
- [ ] `app/controllers/admin/crm/email_sends_controller.rb` — new (form), create (enqueue job)
- [ ] `app/controllers/admin/crm/audits_controller.rb` — index (activity log for a lead)
- [ ] `app/controllers/admin/webhooks/calendly_controller.rb` — create only; **skips admin session authentication** (webhook source); performs signature verification inline before enqueuing job; responds 200 immediately

All controllers: Pundit `authorize` on every action. Thin — delegate to service objects.

---

### Frontend

**Kanban Board (`/admin/crm/leads`)**

- [ ] ViewComponent: `app/components/crm/kanban_board_component.rb` — renders stage columns; receives grouped leads hash
- [ ] ViewComponent: `app/components/crm/lead_card_component.rb` — single Kanban card (name, contact, last activity, assigned rep avatar)
- [ ] Stimulus controller: `app/javascript/controllers/crm_kanban_controller.js`
  - Initialises Sortable.js on each stage column
  - On drag end: fires PATCH to `/admin/crm/leads/:id/transition` with `{ stage: targetColumn }` via `fetch` with CSRF token
  - On success: Turbo replaces the moved card via Turbo Stream response; on failure: reverts card to original column and shows flash toast
- [ ] Stimulus controller: `app/javascript/controllers/crm_lead_detail_controller.js`
  - Manages the slide-out detail panel (opens on card click)
  - Handles tab switching between Notes, Activity, and Email tabs within the panel

**Lead Detail Panel**

- [ ] ViewComponent: `app/components/crm/lead_detail_component.rb` — full detail view rendered in a Turbo Frame (`<turbo-frame id="crm_lead_detail">`)
- [ ] ViewComponent: `app/components/crm/lead_notes_component.rb` — note list + inline compose form; submits via Turbo Stream; new note prepended without full-page reload
- [ ] ViewComponent: `app/components/crm/lead_activity_log_component.rb` — audit trail list; paginated (20 per page); rendered in a Turbo Frame
- [ ] ViewComponent: `app/components/crm/lead_email_form_component.rb` — email compose form (To pre-filled, Subject, Body with basic formatting); submit enqueues `CrmSendLeadEmailJob`

**Conversion Flow**

- [ ] When a rep clicks "Mark as Converted", a modal prompts them to search for or create the linked `Restaurant` record. Uses an existing autocomplete Stimulus pattern targeting the `restaurants` table. Sets `restaurant_id` on the lead before calling the `convert` endpoint.

**No ActionCable required for v1.** The Kanban board is a per-user view; realtime multi-user board sync is deferred to v2.

---

### Mailer

- [ ] `app/mailers/crm_mailer.rb`
  - `lead_follow_up(crm_email_send)` — renders from a flexible template with subject and body provided by the sender; uses existing branded `mailer.html.erb` layout
- [ ] `app/views/crm_mailer/lead_follow_up.html.erb` + `.text.erb`

---

### API / Webhooks

**Calendly Webhook**

- Endpoint: `POST /admin/webhooks/calendly`
- Authentication: HMAC-SHA256 signature verification via `Crm::CalendlyWebhookVerifier` (shared secret in Rails credentials as `calendly_webhook_secret`)
- This endpoint **bypasses** the admin session `before_action` (added to `skip_before_action`) but is not publicly documented
- Responds `200 OK` immediately after enqueuing job; `401` on signature failure; `422` on unparseable payload
- Idempotency: `calendly_event_uuid` unique partial index prevents double-processing

---

## Security & Authorization

- [ ] All CRM routes are within the `admin/` namespace and protected by the existing admin `before_action` (Devise admin scope)
- [ ] Pundit policies (`CrmLeadPolicy`, `CrmLeadNotePolicy`, `CrmEmailSendPolicy`) enforce admin-only access — no restaurant `owner`, `staff`, or `customer` role may access any CRM action
- [ ] Calendly webhook endpoint skips session auth but enforces HMAC-SHA256 signature check — unauthenticated requests receive `401` with no body
- [ ] `lost_reason` and `contact_email` are never exposed in Turbo Stream fragments sent to non-admin contexts (not applicable given admin-only scope, but confirmed by policy)
- [ ] `CrmLeadAudit` records are immutable at the application layer — no `update` or `destroy` routes exist; database-level: consider a `RULE` or trigger in a future migration if compliance requires it
- [ ] No PCI data is stored in any CRM model
- [ ] GDPR: `contact_email` and `contact_name` constitute personal data; document in the platform's data register; add to the data deletion procedure for admin-requested erasure
- [ ] RackAttack: the Calendly webhook endpoint is rate-limited to 60 requests/minute per IP
- [ ] Brakeman scan clean before merge

---

## Testing Plan

- [ ] Model specs:
  - `test/models/crm_lead_test.rb` — stage enum, validations, `converted` requires `restaurant_id`, `lost` requires `lost_reason`
  - `test/models/crm_lead_note_test.rb` — presence validations
  - `test/models/crm_lead_audit_test.rb` — immutability (no update/destroy callbacks), created_at only
  - `test/models/crm_email_send_test.rb` — presence validations

- [ ] Service specs:
  - `test/services/crm/lead_transition_service_test.rb` — valid forward transitions, invalid backward transitions (except lost→contacted), precondition enforcement (convert without restaurant_id raises), audit record written on every transition
  - `test/services/crm/lead_audit_writer_test.rb` — creates correct audit record structure
  - `test/services/crm/calendly_webhook_verifier_test.rb` — valid sig passes, invalid sig raises, missing sig raises
  - `test/services/crm/calendly_event_handler_test.rb` — known lead advanced to demo_booked, unknown email auto-creates a `CrmLead` with `source: 'calendly'` / `assigned_to_id: nil` / `stage: 'demo_booked'`, idempotency via duplicate event UUID

- [ ] Controller/request specs:
  - `test/controllers/admin/crm/leads_controller_test.rb` — CRUD, transition, convert, reopen; non-admin gets 403
  - `test/controllers/admin/crm/notes_controller_test.rb` — create/destroy; non-admin 403
  - `test/controllers/admin/webhooks/calendly_controller_test.rb` — valid sig 200, invalid sig 401, duplicate event UUID 200 (no-op)

- [ ] System/integration test:
  - `test/system/crm_kanban_test.rb` — drag card to new column, verify PATCH fires, verify card in correct column after response
  - `test/system/crm_lead_email_test.rb` — compose and send email, verify `CrmEmailSend` record and audit entry created

- [ ] Edge cases:
  - Lead already in `converted` stage receives a Calendly webhook for `demo_booked` — transition is a no-op (already past that stage)
  - Calendly webhook arrives before a `CrmLead` exists for that email — auto-creates lead with `source: 'calendly'`, `assigned_to_id: nil`, `stage: 'demo_booked'`; verify lead appears in "Needs Assignment" board filter
  - Email send job fails on final retry — verify dead-letter and no duplicate `CrmEmailSend` record

- [ ] Run: `bin/fast_test` — all passing

---

## Implementation Checklist

### Setup
- [ ] Feature flag created in Flipper: `crm_sales_funnel`
- [ ] New Sidekiq queue `crm` added to `config/sidekiq.yml`
- [ ] Calendly webhook secret added to Rails credentials (`calendly_webhook_secret`)
- [ ] Database migrations written and reviewed by a second engineer (new tables, no existing table modifications)

### Core Implementation
- [ ] `CrmLead`, `CrmLeadNote`, `CrmLeadAudit`, `CrmEmailSend` models created with validations
- [ ] Stage enum defined on `CrmLead`
- [ ] `CrmLeadPolicy`, `CrmLeadNotePolicy`, `CrmEmailSendPolicy` written
- [ ] `Crm::LeadTransitionService` implemented and tested
- [ ] `Crm::LeadAuditWriter` implemented
- [ ] `Crm::CalendlyWebhookVerifier` implemented
- [ ] `Crm::CalendlyEventHandler` implemented
- [ ] `Crm::LeadEmailSender` implemented
- [ ] `Crm::ProcessCalendlyWebhookJob` implemented
- [ ] `Crm::SendLeadEmailJob` implemented
- [ ] `CrmMailer` and email templates created
- [ ] All controllers and routes wired up
- [ ] Pundit `authorize` called on every controller action

### Frontend
- [ ] Kanban board ViewComponents built
- [ ] `crm_kanban_controller.js` Stimulus controller with Sortable.js
- [ ] `crm_lead_detail_controller.js` Stimulus controller with tab management
- [ ] Lead detail slide-out panel and ViewComponents
- [ ] Notes compose form with Turbo Stream response
- [ ] Activity log with pagination
- [ ] Email compose form
- [ ] Conversion modal with restaurant autocomplete
- [ ] Responsive layout verified (1280px+ primary target; 768px usable minimum)

### Quality
- [ ] All tests written and passing (`bin/fast_test`)
- [ ] RuboCop clean (`bundle exec rubocop`)
- [ ] Brakeman clean (`bundle exec brakeman`)
- [ ] JS/CSS lint clean (`yarn lint`)
- [ ] Docs regenerated (`bin/generate_docs`)

### Release
- [ ] Feature flag `crm_sales_funnel` enabled for admin users only in Flipper
- [ ] Migrations safe for zero-downtime deploy (additive only; no column renames or drops)
- [ ] Calendly webhook URL registered in Calendly developer dashboard
- [ ] Sidekiq `crm` queue worker count documented in ops runbook
- [ ] GDPR data register updated with `contact_email` / `contact_name` fields

---

## Confirmed Design Decisions

- **Unmatched Calendly webhooks**: When a Calendly `invitee.created` event arrives and no `CrmLead` exists for that email, the system auto-creates a new `CrmLead` with `source: 'calendly'`, `assigned_to_id: nil`, and `stage: 'demo_booked'`. These unowned leads are surfaced via a "Needs Assignment" filter on the Kanban board so a manager can assign them promptly.

---

## Open Questions

1. **`trial_active` auto-transition**: The spec designates `trial_active` as automatically triggered when a `Restaurant` record is linked. The mechanism needs a decision: (a) an `after_create` callback on `Restaurant` that checks for a matching `CrmLead` by email and calls `LeadTransitionService`, or (b) a manual step in the convert flow that immediately sets the stage to `trial_active`. Option (a) is more automated but introduces a cross-model coupling. Recommend option (b) for v1 simplicity.

2. **Email reply tracking**: Outbound emails are sent but replies are not captured. Sales reps need to understand this limitation. A v2 option is to use a reply-to address with a unique token that routes into a `CrmEmailReply` model via an inbound email parser (e.g. ActionMailbox, which is already in Rails 7.2). Deferred.

3. **Sortable.js availability**: Confirm whether Sortable.js is already in `package.json` before implementation begins. If not, add `sortablejs` via `yarn add sortablejs` — no gem required.

4. **Lost reason taxonomy**: Should `lost_reason` be a free-text field or a constrained enum (e.g. `'price'`, `'competitor'`, `'no_response'`, `'not_a_fit'`, `'timing'`)? An enum enables funnel loss analysis by reason. Recommendation: constrained enum with an `'other'` option plus a `lost_reason_notes` free-text field.

---

## References

- Related spec: `docs/features/todo/backlog/employee-role-promotion.md` (pattern reference for admin-only Pundit policies)
- Related spec: `docs/features/todo/backlog/strikepay-integration.md` (pattern reference for webhook verification service structure)
- Calendly webhook documentation: https://developer.calendly.com/api-docs/ZG9jOjM2MzE2MDM4-webhook-signatures
- Existing admin namespace: `app/controllers/admin/`
- Existing branded mailer layout: `app/views/layouts/mailer.html.erb`
