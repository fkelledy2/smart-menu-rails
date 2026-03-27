---
name: CRM Sales Funnel v1 implementation decisions and gotchas
description: CRM Sales Funnel #9 implementation — admin-only Kanban CRM, stage transitions, Calendly webhook, audit trail (March 2026)
type: project
---

CRM Sales Funnel (#9) shipped 2026-03-27. Admin-only sales pipeline tool at `/admin/crm/leads`.

**Why:** Sales team needed a structured acquisition pipeline before launch to convert inbound restaurant interest into paying customers. This is growth-critical internal tooling.

**How to apply:** Use this as the reference pattern for admin-only CRM-style features. Key decisions:

## Critical Bugs Fixed During Completion

1. **`enum :stage` with `new` value** — Rails 7.2 enum generates `new?` predicate which conflicts with `new_record?`. Fix: use `prefix: :stage` so predicates become `stage_lost?`, `stage_converted?`, etc. All model validations use `if: :stage_lost?` / `if: :stage_converted?`.

2. **`ActiveRecord::ReadonlyRecord` doesn't exist** in this Rails 7.2 version. Used a custom `CrmLeadAudit::ImmutableRecordError < StandardError` instead.

3. **`dependent: :destroy` on audit records** — `CrmLead has_many :crm_lead_audits` with `dependent: :destroy` conflicts with the immutability `before_destroy` callback. Changed to `dependent: :delete_all` which bypasses callbacks.

4. **Namespace resolution in admin/crm/ controllers** — Code inside `module Admin; module Crm;` resolves `Crm::LeadTransitionService` as `Admin::Crm::LeadTransitionService`. Must use `::Crm::LeadTransitionService` (double-colon prefix) for all service/job references inside the Admin::Crm namespace.

5. **counter_cache column name** — `CrmLeadNote belongs_to :crm_lead, counter_cache: :notes_count` (not the default `crm_lead_notes_count` which would conflict with the migration's `notes_count` column).

6. **form_with model routing** — `form_with model: [:admin, :crm, lead]` generates `admin_crm_crm_lead_path` (double `crm_`). Fix: explicit URL `form_with model: lead, url: lead.new_record? ? admin_crm_leads_path : admin_crm_lead_path(lead)`.

7. **Asset manifest for Stimulus controllers** — `pin_all_from 'app/javascript/controllers'` in importmap.rb exposes all controller JS files via Sprockets. New controllers must be declared in `app/assets/config/manifest.js` as `//= link controllers/crm_kanban_controller.js` so Sprockets can serve them in test/production. The `app/javascript/` path IS in Sprockets asset paths, so this works.

8. **Calendly webhook `return` inside `begin..rescue` assignment** — RuboCop `Lint/NoReturnInBeginEndBlocks`. Refactor to private helper methods `verify_signature` / `parse_payload` that return booleans/nil.

## Architecture

- **4 new models**: `CrmLead`, `CrmLeadNote`, `CrmLeadAudit`, `CrmEmailSend`
- **3 new policies**: `CrmLeadPolicy`, `CrmLeadNotePolicy`, `CrmEmailSendPolicy` — all `mellow_admin?` gates
- **5 service objects**: `Crm::LeadTransitionService`, `LeadAuditWriter`, `CalendlyWebhookVerifier`, `CalendlyEventHandler`, `LeadEmailSender`
- **2 jobs**: `Crm::ProcessCalendlyWebhookJob` (queue: `crm`), `Crm::SendLeadEmailJob` (queue: `mailers`)
- **Idempotency check in service**: `call` method short-circuits before validation when `lead.stage == new_stage`
- **Calendly webhook skips admin auth**: uses `ActionController::Base` subclass with `protect_from_forgery with: :null_session`

## Test Pattern

- Controller tests for admin namespace use `Flipper.enable(:crm_sales_funnel, @mellow_admin)` in setup and `Flipper.disable(:crm_sales_funnel)` in teardown
- HTML-rendering controller tests fail with `application.css not present` (pre-existing infra issue) — accepted by the team
- Posting malformed JSON to webhook endpoint: use `env: { 'RAW_POST_DATA' => body, 'CONTENT_TYPE' => 'text/plain' }` to bypass Rails param parsing

## Flipper Flag

`crm_sales_funnel` — gates the entire CRM UI for admin users
