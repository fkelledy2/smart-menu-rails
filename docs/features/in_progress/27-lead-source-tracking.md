# Lead Source Tracking + Website Inbound Lead Ingestion

## Status
- Priority Rank: #27
- Category: Growth
- Effort: M
- Dependencies: CRM Sales Funnel (#9, completed); `CrmLead`, `CrmLeadNote`, `CrmLeadAudit` models (all built); `Crm::LeadAuditWriter` service (built); RackAttack (built)
- Refined: true

---

## Problem Statement

mellow.menu's homepage contact form currently delivers submissions by email to admin@mellow.menu only — no CRM record is created. As inbound interest grows, submissions are invisible to the sales workflow, cannot be tracked against manually entered or city-discovery leads, and cannot be reported on. The `source` column already exists on `crm_leads` (plain string, nullable) but carries no enforced values, no enum, and no UI surface. This feature: (1) enforces a normalised source enum on `CrmLead`, (2) wires the homepage contact form directly into the CRM via a background ingestion job, (3) prevents duplicate lead creation, (4) tags website-originated leads as unsolicited inbound, and (5) surfaces source in the CRM list and detail views.

---

## Success Criteria

- Every homepage contact form submission creates or updates a `CrmLead` with `source = 'website_inbound'`
- The raw submission is preserved as an immutable `WebsiteContactSubmission` record regardless of deduplication outcome
- Duplicate detection prevents a second lead being created when the email, phone, or company+name already matches an existing lead
- An existing lead that matches receives a new `CrmLeadNote` (system-authored) instead of a duplicate record
- Source is non-null across all leads (backfilled to `'manual'` for existing records, `'city_discovery'` where provenance is known)
- Website-inbound leads are tagged `unsolicited` and `inbound`
- Admin email notification to admin@mellow.menu continues to fire for every submission (new lead or matched existing)
- CRM list view has a source column and a source filter
- CRM lead detail view shows source, tags, and the original submission summary
- Manual lead creation defaults to `source = 'manual'`; city discovery creation sets `source = 'city_discovery'`
- The ingestion job is idempotent — retrying a submission never creates duplicate leads
- All system-triggered actions are auditable via `CrmLeadAudit`

---

## User Stories

- As a sales admin, I want every homepage contact form submission to automatically appear as a CRM lead so that no inbound interest slips through the cracks.
- As a sales admin, I want to filter the lead list by source so that I can focus follow-up effort on website-inbound leads separately from proactively sourced leads.
- As a sales admin, I want to see on a lead's detail page where the lead originated and what they originally wrote in the contact form.
- As a platform admin, I want source changes to be audited (old value, new value, actor, timestamp) so that I can trust the integrity of the source field for reporting.
- As a website visitor, I want to submit a contact form and receive a prompt confirmation that my message was received.

---

## Functional Requirements

1. **Source enum on `CrmLead`**: Enforce `source` as a string-backed enum with values `manual`, `city_discovery`, `website_inbound`, `other`. Default is `'manual'`. The column already exists; this requirement adds validation, the enum declaration, and a non-null constraint after backfill.

2. **Tagging**: Introduce a `CrmLeadTag` join model and `crm_lead_tags` table (lead_id, tag — string, unique index on the pair). Apply tags `unsolicited` and `inbound` to all `website_inbound` leads at creation time via `Crm::LeadTagger`. Tags are additive — never removed on deduplication update.

3. **`WebsiteContactSubmission` model**: Immutable raw artifact capturing the full submission. Fields: `name`, `email`, `phone`, `company_name`, `restaurant_name`, `website`, `message` (text), `submitted_at`, `ip_address`, `user_agent`, `referrer`, `utm_source`, `utm_medium`, `utm_campaign`, `processing_status` (string enum: `pending`, `processed`, `rejected_as_spam`, `failed`), `error_message`, `processed_at`, `lead_id` (FK to `crm_leads`, nullable). Record is created synchronously in the controller before the job is enqueued; never mutated except for the processing fields.

4. **Contact form endpoint**: New public `WebsiteContactsController#create` at `POST /contact`. Accepts: `name` (required), `email` (required), `message` (required), `company_name` (optional), `restaurant_name` (optional), `phone` (optional). Honeypot field `website` — any non-blank value sets `processing_status = 'rejected_as_spam'` and halts job enqueue. Responds with Turbo Stream confirmation on success or validation error inline.

5. **`ProcessWebsiteContactSubmissionJob`**: Sidekiq job enqueued after submission record is created. Guards against double-processing using `processed_at` presence check + `WITH (SKIP LOCKED)` row-level lock. Steps:
   a. Run `Crm::LeadMatcher` — returns an existing `CrmLead` or nil.
   b. If no match: run `Crm::LeadCreatorFromWebsiteSubmission` — creates `CrmLead` with `source = 'website_inbound'`.
   c. If match: append a `CrmLeadNote` (system-authored, body includes submission summary); do NOT overwrite `source` if existing source is `manual` or `city_discovery` (stronger sources take precedence).
   d. Run `Crm::LeadTagger` — applies `unsolicited` and `inbound` tags to the lead (idempotent).
   e. Write `CrmLeadAudit` via `Crm::LeadAuditWriter` — event `lead_created` or `inbound_submission_matched`.
   f. Send notification email via `CrmMailer#inbound_lead_notification` to admin@mellow.menu.
   g. Update `WebsiteContactSubmission`: set `lead_id`, `processed_at`, `processing_status = 'processed'`.
   On unhandled exception: set `processing_status = 'failed'`, `error_message`, re-raise for Sidekiq retry.

6. **Deduplication rules** (evaluated in priority order by `Crm::LeadMatcher`):
   1. Exact `contact_email` match (case-insensitive)
   2. Exact `contact_phone` match (if submission phone is present)
   3. Exact `restaurant_name` + `contact_name` match (both normalised to downcase strip)
   4. No match → create new lead

7. **Source precedence on update**: Source values are ranked `manual > city_discovery > website_inbound > other`. `Crm::LeadCreatorFromWebsiteSubmission` (and any future ingestion services) must not overwrite a higher-ranked source on an existing lead.

8. **Admin UI — lead list**: Add `source` column to the CRM leads table. Add a source filter (dropdown). Add an `inbound` badge filter (any lead tagged `inbound`).

9. **Admin UI — lead detail**: Display `source` (human-readable label), tags (badge list), and a collapsible "Original Submission" panel showing the `WebsiteContactSubmission` fields when `source = 'website_inbound'`.

10. **Admin UI — lead create/edit form**: `source` field defaults to `manual`. Visible and editable only by users with admin or sales_manager role. Changes to `source` write a `field_updated` `CrmLeadAudit` event via `Crm::LeadAuditWriter`.

11. **CRM dashboard — lead count by source**: Add a simple breakdown count card to the CRM dashboard (existing `Admin::Crm::DashboardController`) showing lead counts per source value for the last 30 days.

12. **Email continuity**: `CrmMailer#inbound_lead_notification` replaces the current direct email from the contact form. It must deliver to admin@mellow.menu with the submission body, contact details, and a direct link to the CRM lead record.

13. **Spam protection**:
    - Honeypot field `website` on the contact form (hidden via CSS, not `display:none` — use `aria-hidden` + `position: absolute; left: -9999px`)
    - Server-side: blank `name`/`email`/`message` blocked by validation
    - RackAttack rule: 5 submissions per IP per 10 minutes; 3 submissions per email per hour
    - Basic blocked-domain list checked in `Crm::LeadMatcher` / `Crm::LeadCreatorFromWebsiteSubmission` — submissions from known disposable email domains set `processing_status = 'rejected_as_spam'`

---

## Non-Functional Requirements

- **Idempotency**: The job must be safe to retry. The `processed_at` guard + row-level lock ensures no duplicate leads are created on Sidekiq retry.
- **Durability**: `WebsiteContactSubmission` is created synchronously before the job enqueues — if Sidekiq is down, the record is preserved and can be reprocessed.
- **Performance**: All new queries against `crm_leads` for deduplication use indexed columns (`contact_email`, `contact_phone`). No query should exceed 5s on the primary. Job processing should complete in under 2s for the happy path.
- **No new gems**: RackAttack (existing), Sidekiq (existing), ActionMailer (existing) cover all requirements.
- **Security**: The contact form endpoint is public-facing — RackAttack rate limiting and honeypot are mandatory before launch. IP address stored on submission for abuse investigation.
- **GDPR note**: `WebsiteContactSubmission` stores PII (name, email, phone, IP). Retention policy should be aligned with the platform's existing data retention stance — flag for legal review before public launch. Submissions are linked to `CrmLead`; if a lead is deleted, the submission `lead_id` should nullify (not cascade delete) to preserve the submission record.

---

## Technical Notes

### Existing infrastructure confirmed in codebase
- `CrmLead` model at `app/models/crm_lead.rb` — `source` column exists as plain nullable string; no enum defined yet
- `CrmLeadNote` at `app/models/crm_lead_note.rb` — `belongs_to :author, class_name: 'User'`; system notes will use `author_id: nil` with a guard or a dedicated `created_by_system` boolean (see Open Questions)
- `CrmLeadAudit` at `app/models/crm_lead_audit.rb` — immutable; `EVENTS` array must be extended with `inbound_submission_matched`
- `Crm::LeadAuditWriter` at `app/services/crm/lead_audit_writer.rb` — all audit writes must flow through this service
- `Crm::LeadTransitionService`, `Crm::LeadEmailSender` — existing service patterns to follow for new services

### New migrations
- [ ] `add_source_enum_to_crm_leads` — add `null: false` constraint to `source` after backfill; add index `index_crm_leads_on_source`
- [ ] `backfill_crm_leads_source` — data migration setting `source = 'manual'` for all existing records where `source IS NULL`; `'city_discovery'` for records linked via `discovered_restaurant_id` (verify logic before running)
- [ ] `create_crm_lead_tags` — `id`, `crm_lead_id` (FK), `tag` (string, not null), `created_at`; unique index on `(crm_lead_id, tag)`
- [ ] `create_website_contact_submissions` — full column list per Functional Requirement 3; index on `email`; index on `processing_status`; `lead_id` FK with `on_delete: :nullify`

### New models
- [ ] `CrmLeadTag` — `belongs_to :crm_lead`; validates `tag` presence and inclusion in `VALID_TAGS = %w[unsolicited inbound].freeze`; unique constraint on `[crm_lead_id, tag]`
- [ ] `WebsiteContactSubmission` — full fields per FR 3; `belongs_to :crm_lead, optional: true`; `processing_status` enum (string-backed); immutable except for processing fields (guard `before_update` on non-processing columns); scopes: `pending`, `failed`, `rejected_as_spam`

### Updates to existing models
- [ ] `CrmLead` — add string-backed enum `source` with values `manual`, `city_discovery`, `website_inbound`, `other`; `validates :source, presence: true`; `has_many :crm_lead_tags, dependent: :destroy`; `has_one :website_contact_submission` (optional); add scope `by_source`
- [ ] `CrmLeadAudit` — extend `EVENTS` with `'inbound_submission_matched'`
- [ ] `CrmLeadNote` — add `created_by_system` boolean (default false, not null) to support system-authored notes without requiring a User record

### New services (all under `app/services/crm/`)
- [ ] `Crm::LeadMatcher` — deduplication lookup; takes submission attributes; returns `CrmLead` or nil; pure query object, no writes
- [ ] `Crm::LeadCreatorFromWebsiteSubmission` — creates `CrmLead` from a `WebsiteContactSubmission`; sets `source = 'website_inbound'`; returns the new lead
- [ ] `Crm::LeadTagger` — applies one or more tags to a `CrmLead`; idempotent (`find_or_create_by`)
- [ ] `Crm::InboundSubmissionNoteWriter` — writes a system `CrmLeadNote` summarising the submission on a matched existing lead; calls `Crm::LeadAuditWriter` after

### New job
- [ ] `app/jobs/crm/process_website_contact_submission_job.rb` — Sidekiq, `default` queue; takes `submission_id`; idempotency guard on `processed_at`; wraps all steps in a transaction; rescues and writes `failed` status on error

### New mailer action
- [ ] `CrmMailer#inbound_lead_notification` — delivers to admin@mellow.menu; includes contact details, message body, link to CRM lead; replaces any prior direct delivery from the contact form

### Controller and routes
- [ ] `POST /contact` → `WebsiteContactsController#create` (public, no auth); rate-limited by RackAttack
- [ ] No new admin controller needed — extend existing `Admin::Crm::LeadsController` for source filter param
- [ ] Extend `Admin::Crm::DashboardController` with source breakdown query

### Pundit
- [ ] `CrmLeadPolicy` — extend `update?` to allow `source` field mutation only for `admin` or `sales_manager` roles; all other roles receive the field as read-only
- [ ] `WebsiteContactSubmissionPolicy` — admin read-only; no create/update/destroy from UI (managed by system only)
- [ ] `CrmLeadTagPolicy` — admin read-only; tags applied only via services

### Frontend
- [ ] Contact form Stimulus controller: `app/javascript/controllers/website_contact_form_controller.js` — handles inline validation, honeypot field placement, and Turbo Stream confirmation swap
- [ ] CRM lead list: source column + source filter dropdown (Turbo Frame filter, existing pattern from kanban filters)
- [ ] CRM lead detail: source badge, tags badge list, collapsible "Original Submission" panel (ViewComponent: `Crm::SubmissionSummaryComponent`)
- [ ] CRM dashboard: source breakdown count card

### Flipper flag
- [ ] `website_inbound_leads` — gates the public contact form endpoint and the job enqueue; admin notification email fires regardless of flag state so no submissions are silently dropped during rollout

---

## Acceptance Criteria

1. Given a visitor submits the homepage contact form with a unique email address, a new `CrmLead` is created with `source = 'website_inbound'`, tagged `unsolicited` and `inbound`, and a `CrmLeadAudit` record with event `lead_created` is written.
2. Given a visitor submits the form with an email address matching an existing `CrmLead`, no new lead is created; a `CrmLeadNote` (system-authored) is appended to the existing lead and a `CrmLeadAudit` record with event `inbound_submission_matched` is written.
3. Given the existing lead has `source = 'manual'` or `source = 'city_discovery'`, the source is not overwritten after a website inbound match.
4. Given a submission with a non-blank `website` honeypot field, the `WebsiteContactSubmission` is saved with `processing_status = 'rejected_as_spam'` and no lead is created or updated.
5. Given the `ProcessWebsiteContactSubmissionJob` is retried after a transient failure, no duplicate lead or duplicate note is created.
6. Given a sales admin views the CRM lead list, a source column is visible and a source filter dropdown is present and functional.
7. Given a sales admin views the detail page of a `website_inbound` lead, the source label, tags, and original submission summary are visible.
8. Given a sales admin creates a lead manually via the CRM form, the source defaults to `manual` and is saved correctly.
9. Given the city discovery flow creates a lead, `source = 'city_discovery'` is set.
10. Given a submission is processed, an email notification is delivered to admin@mellow.menu containing the contact details and message.
11. Given an IP submits the contact form more than 5 times in 10 minutes, subsequent requests are throttled by RackAttack with a 429 response.
12. All existing `crm_leads` rows have `source = 'manual'` (or `'city_discovery'` where provenance is confirmed) after the backfill migration runs.

---

## Out of Scope (Phase 1)

- Full marketing attribution stack (UTM parameter capture is included in the `WebsiteContactSubmission` schema for future use but not surfaced in the CRM UI)
- Email reply automation
- Spam scoring via third-party enrichment services
- Deduplication beyond the three rules specified (no fuzzy matching, no phone normalisation beyond exact match)
- Parsing of the existing admin@mellow.menu mailbox retrospectively
- Phase 2 UTM reporting
- Phase 3 additional source values: `partner_referral`, `paid_ads`, `organic_search`, `event`, `api_import`
- Mobile app support

---

## Open Questions

1. **System-authored `CrmLeadNote`**: The current `CrmLeadNote` model requires `author` (User). Two options: (a) add `created_by_system boolean` to `crm_lead_notes` and make `author` optional when `created_by_system = true`, or (b) use a dedicated system `User` record (`system@mellow.menu`). Option (a) is preferred to avoid polluting the User table — confirm before implementing.
2. **Backfill for `city_discovery`**: The migration can set `source = 'city_discovery'` for leads with a non-null `discovered_restaurant_id`. Confirm this heuristic is exhaustive — are there any `city_discovery` leads without a `discovered_restaurant_id` link (e.g. early records)?
3. **Contact form location**: Is the contact form exclusively on the homepage, or should it also be reachable at a dedicated `/contact` page? The route is `POST /contact` either way, but the GET view needs a home.
4. **Source field editability**: Spec says admin and sales_manager can edit source. Confirm whether the `sales` role (if distinct from `sales_manager`) should also have edit rights.
5. **Tag extensibility**: `CrmLeadTag` is scoped to `VALID_TAGS = %w[unsolicited inbound]` for now. Should future tags (e.g. `hot`, `priority`) be added here or handled by a separate priority/label system?
6. **Submission retention**: Is there a retention period after which `WebsiteContactSubmission` records should be purged? This intersects with GDPR — flag for legal review before the endpoint goes public.
