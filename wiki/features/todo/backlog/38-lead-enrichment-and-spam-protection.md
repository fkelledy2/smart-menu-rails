# Feature Spec: Lead Enrichment & Contact Form Spam Protection

**Status**: Backlog
**Created**: 2026-04-04
**Author**: Feature Backlog Agent
**Flipper Flag**: `crm_lead_enrichment` (new, under existing `crm_sales_funnel` parent check)

---

## Overview

Two tightly coupled improvements to the CRM inbound pipeline. First, when a `CrmLead` is created or its email address changes, an async background job calls the Hunter.io Enrichment API (chosen over Clearbit — see provider rationale below) to resolve the contact's company name, company domain, employee count, industry, and LinkedIn/Twitter URLs from their email address. Enrichment data is stored on the `CrmLead` record in a dedicated `jsonb` column and surfaced as a compact panel on the lead detail view and kanban card. Second, the public `ContactsController#create` action is hardened against bot spam by activating the already-installed `invisible_captcha` gem (honeypot + timestamp check) and adding a targeted `RackAttack` throttle — both zero-friction mechanisms that require no reCAPTCHA widget or third-party JS.

Primary users: mellow.menu internal sales admins via the CRM pipeline (`/admin/crm/leads`).

---

## Goals

- [ ] Enrich every new `CrmLead` that has a `contact_email` via async Hunter.io API call
- [ ] Re-enrich when `contact_email` is updated on an existing lead
- [ ] Store enrichment data in a structured, queryable `jsonb` column on `crm_leads`
- [ ] Surface enrichment data (company, industry, size, social links) on the lead detail card and kanban card
- [ ] Gracefully handle enrichment failure, API limits, and un-enrichable addresses (personal/disposable emails)
- [ ] Block automated/bot contact form submissions via `invisible_captcha` honeypot + timestamp guard
- [ ] Add a `RackAttack` throttle for `POST /contacts` (3 per IP per 10 minutes)
- [ ] All enrichment actions written to `CrmLeadAudit` so they are visible in the activity log

## Non-Goals (Out of Scope for v1)

- Company logo fetching or display (adds storage complexity; defer to v2)
- Enriching leads that have no email address (phone-only or name-only leads)
- Bulk re-enrichment of historical leads via a UI action (can be done via Rails console or rake task if needed)
- Enrichment confidence scoring or manual enrichment override UI
- reCAPTCHA v3 / hCaptcha / Cloudflare Turnstile (no external JS widget needed given invisible_captcha covers the threat)
- Automatic lead scoring based on enrichment data

---

## Provider Rationale

### Why Hunter.io over Clearbit

| Criteria | Hunter.io | Clearbit | Apollo.io |
|---|---|---|---|
| Free tier | 25 enrichments/month | 0 (deprecated Enrichment API, paid only) | Limited, aggressive upsell |
| Pricing at scale | ~$49/mo for 500 enrichments | $99+/mo minimum | $49/mo, bundled with CRM features we don't need |
| Maintenance status | Active, well-documented v2 API | Clearbit was acquired by HubSpot in 2023; Enrichment API deprecated for new sign-ups | Active but primarily a CRM/outreach tool |
| Rails gems | `hunter_io` gem (maintained) **or** plain `HTTParty` (already in Gemfile) | `clearbit` gem (unmaintained, last commit 2022) | No official gem |
| Data focus | Email → company enrichment, email verification | Broader person + company graph | Broader CRM context |
| GDPR | EU data processing covered under their DPA | HubSpot DPA applies post-acquisition — complexity | EU hosting available |

**Decision**: Use Hunter.io's Person Enrichment endpoint (`GET https://api.hunter.io/v2/email-finder` or `/enrichment`) via `HTTParty`, which is already in the Gemfile. No new gem required. Store the raw API response in `enrichment_raw jsonb` for future re-parsing if the response shape changes.

---

## User Stories

**As a sales admin**, I want to open a CRM lead and immediately see the contact's company, industry, and employee count — without manually researching it — so that I can tailor my outreach before making first contact.

**As a sales admin**, I want the kanban card to show an industry badge on enriched leads so that I can visually assess the pipeline composition at a glance.

**As a platform admin**, I want contact form submissions from bots to be silently rejected before they create noise in the CRM so that the lead list stays clean without manual pruning.

**As a sales admin**, I want enrichment attempts and outcomes logged in the lead's activity tab so that I know when data was last fetched and whether it succeeded.

---

## Technical Design

### Architecture Notes

The enrichment flow is fully async: `CrmLead` after_commit callbacks enqueue `Crm::EnrichLeadJob`. The job calls `Crm::LeadEnrichmentService`, which wraps the Hunter.io API via `HTTParty`. Results are written back to `CrmLead#enrichment_data` (jsonb) and `CrmLead#enrichment_status` (string enum). Failures are retried with Sidekiq's built-in exponential backoff (3 retries). A permanent failure sets `enrichment_status = 'failed'` and logs to `CrmLeadAudit`.

Spam protection activates the already-present `invisible_captcha` gem at the controller level — one `invisible_captcha` call in the controller and one helper call in the view form. A targeted `RackAttack` throttle is added to `config/initializers/rack_attack.rb`. No new dependency. No user-visible change.

Both sub-features are gated behind `Flipper.enabled?(:crm_lead_enrichment)`. Spam protection is additionally safe to enable unconditionally (it's purely defensive), but the flag keeps both changes deployable together.

### New Dependencies

No new gems required.

- Hunter.io API called via `HTTParty` (already in Gemfile: `gem 'httparty'`)
- `invisible_captcha ~> 2.3` already in Gemfile and initializer configured; just needs activation in controller + view
- `rack-attack` already in Gemfile and initializer; just needs a new throttle block

New environment variable required: `HUNTER_IO_API_KEY` (stored in Heroku Config Vars, referenced via `ENV.fetch('HUNTER_IO_API_KEY')`)

### Data Model Changes

- [ ] Migration: add `enrichment_data jsonb` to `crm_leads` (default: `{}`, null: false)
- [ ] Migration: add `enrichment_status string` to `crm_leads` (default: `'pending'`, null: false) — values: `pending`, `enriched`, `skipped`, `failed`
- [ ] Migration: add `enrichment_fetched_at datetime` to `crm_leads` (nullable — records when last enrichment was attempted)
- [ ] Index: `index_crm_leads_on_enrichment_status` (for filtering/reporting)
- [ ] No new model needed — data lives on `CrmLead` via jsonb
- [ ] No policy changes — enrichment actions are system-only; `CrmLeadPolicy` already covers `update?` for admin

**`enrichment_data` jsonb shape (persisted)**:
```json
{
  "company_name": "Acme Restaurants Ltd",
  "company_domain": "acmerestaurants.com",
  "company_industry": "Food & Beverages",
  "company_size": "11-50",
  "company_linkedin_url": "https://linkedin.com/company/acme",
  "person_linkedin_url": "https://linkedin.com/in/johnsmith",
  "person_twitter_handle": "johnsmith",
  "source": "hunter_io",
  "fetched_at": "2026-04-04T12:00:00Z"
}
```

**`enrichment_raw` jsonb column** (also added) stores the complete unmodified API response for forward-compatibility.

- [ ] Migration: add `enrichment_raw jsonb` to `crm_leads` (default: `{}`, null: false)

### Service Objects

- [ ] `app/services/crm/lead_enrichment_service.rb` — `Crm::LeadEnrichmentService`
  - Accepts a `CrmLead` record
  - Skips if `contact_email` is blank, or if email domain is in a disposable/personal domain denylist (gmail.com, hotmail.com, yahoo.com, icloud.com, outlook.com — configurable constant)
  - Calls `GET https://api.hunter.io/v2/people/find?email=<email>&api_key=<key>` via `HTTParty`
  - On HTTP 200 + non-empty response: parses and writes `enrichment_data`, `enrichment_raw`, `enrichment_status = 'enriched'`, `enrichment_fetched_at = Time.current`
  - On empty/unresolvable response: sets `enrichment_status = 'skipped'`, `enrichment_fetched_at = Time.current`
  - On HTTP 4xx/5xx or network error: raises `Crm::LeadEnrichmentService::EnrichmentError` (caught by job for retry logic)
  - Writes a `CrmLeadAudit` record with `event = 'enrichment_completed'` or `'enrichment_skipped'` or `'enrichment_failed'`
  - Returns a `Result` struct (pattern consistent with `Crm::LeadTransitionService`)

- [ ] `app/services/crm/lead_enrichment_service.rb` includes a private `PERSONAL_EMAIL_DOMAINS` constant (frozen array) used to skip enrichment for consumer email providers

### Background Jobs

- [ ] `app/jobs/crm/enrich_lead_job.rb` — `Crm::EnrichLeadJob`
  - Queue: `:crm` (existing queue)
  - `sidekiq_options retry: 3`
  - `perform(crm_lead_id:)` — looks up lead, calls `Crm::LeadEnrichmentService.call(lead:)`, handles `EnrichmentError` by re-raising (Sidekiq retries)
  - Idempotent: if `enrichment_status == 'enriched'` and `enrichment_fetched_at` is within 7 days, skip silently

**Trigger points (after_commit on `CrmLead`):**

Add to `CrmLead` model:
```ruby
after_commit :enqueue_enrichment, on: :create, if: :contact_email?
after_commit :enqueue_enrichment, on: :update, if: :saved_change_to_contact_email?
```

The callback calls `Crm::EnrichLeadJob.perform_later(crm_lead_id: id)` only when `Flipper.enabled?(:crm_lead_enrichment)`.

### Controllers & Routes

No new routes or controllers required.

**`ContactsController` changes (spam protection only):**
- [ ] Add `invisible_captcha scope: :contact, on_spam: :handle_spam` to controller
- [ ] Add `handle_spam` private method: logs to Rails.logger, fires `AnalyticsService.track_anonymous_event(..., 'contact_form_spam_blocked')`, renders `new` with a 200 status (silent rejection — do not tell bots they were blocked)
- [ ] No change to `create` action logic; invisible_captcha short-circuits before it is reached

**`rack_attack.rb` addition:**
- [ ] New throttle: `contact_form/ip` — 3 POST `/contacts` per IP per 10 minutes
  ```ruby
  Rack::Attack.throttle('contact_form/ip', limit: 3, period: 10.minutes) do |req|
    req.ip if req.path == '/contacts' && req.post?
  end
  ```

**`Admin::Crm::LeadsController` — no changes required.** Enrichment status is read-only and displayed via views only.

### Frontend

**Kanban card (`app/views/admin/crm/leads/_card.html.erb`):**
- [ ] Add an industry badge below the existing city/type badges when `lead.enrichment_data['company_industry'].present?`
- [ ] Badge style: `text-bg-info` (distinct from existing `text-bg-light` badges)
- [ ] Show only when `enrichment_status == 'enriched'`; show nothing when pending/skipped/failed (no loading spinners on the card — this is background data)

**Lead detail view (`app/views/admin/crm/leads/show.html.erb`):**
- [ ] Add an "Enrichment" card in the left column (below the Contact card) — conditional on `enrichment_status != 'pending'`
- [ ] When `enriched`: render company name, industry, size, company domain (as a link), LinkedIn/Twitter links for both person and company
- [ ] When `skipped`: small muted note "Enrichment not available for this address"
- [ ] When `failed`: small muted warning "Enrichment failed — will retry automatically"
- [ ] When `pending`: show nothing (enrichment is async; page may load before job runs)
- [ ] No Turbo Stream / ActionCable needed — enrichment is not instant; the admin will see data on next page load or modal refresh

**Contact form view (`app/views/contacts/new.html.erb`):**
- [ ] Add `<%= invisible_captcha %>` helper inside the `form_with` block (renders a hidden honeypot field + timestamp token)
- [ ] No visible UI change for legitimate users

**No new Stimulus controllers or ViewComponents required.**

### API / Webhooks

N/A — no new public API endpoints. Hunter.io is an outbound API call only.

---

## Security & Authorization

- [ ] Pundit policy: no changes needed — enrichment is system-initiated; `CrmLeadPolicy` already gates admin access to lead records
- [ ] Tenant scoping: CRM is admin-only (no tenant scoping applies); `enrichment_data` and `enrichment_raw` columns are on `crm_leads` which is already admin-namespace-only
- [ ] `HUNTER_IO_API_KEY` must be stored as a Heroku Config Var — never committed to the repo or logged
- [ ] `Crm::LeadEnrichmentService` must never log the full API key; log only the first 4 characters if debugging is needed
- [ ] `enrichment_raw` stores the raw API response — ensure no PII is leaked to browser; the column is never rendered directly, only parsed fields from `enrichment_data` are shown in views
- [ ] RackAttack throttle on `/contacts` (POST, 3/IP/10min) added to existing `rack_attack.rb`
- [ ] `invisible_captcha` timestamp threshold already set to 2 seconds in initializer — submissions under 2 seconds are rejected (bots fill forms instantly)
- [ ] Silent rejection on spam (render `:new` with 200) prevents bot enumeration of the guard mechanism
- [ ] Brakeman scan: jsonb column access via `lead.enrichment_data['key']` is read-only and HTML-escaped by ERB — no XSS vector
- [ ] No PCI implications (no payment data touched)
- [ ] GDPR: Hunter.io enrichment data is derived from publicly available professional data. Hunter.io's DPA covers B2B enrichment. Personal email domains (gmail, etc.) are skipped — enrichment only runs on professional/business addresses, reducing the likelihood of processing purely personal data.

---

## Testing Plan

- [ ] Model specs `test/models/crm_lead_test.rb`: `after_commit` callback enqueues `Crm::EnrichLeadJob` when `contact_email` present on create; enqueues on email update; does not enqueue when flag disabled
- [ ] Service specs `test/services/crm/lead_enrichment_service_test.rb`:
  - Successful enrichment parses response and writes `enrichment_data` correctly
  - Skips when email domain is in personal denylist
  - Sets `enrichment_status = 'skipped'` when API returns empty result
  - Raises `EnrichmentError` on HTTP 5xx
  - Writes `CrmLeadAudit` record on enrichment success and skip
  - Idempotency: does not call API when lead already enriched within 7 days
- [ ] Job specs `test/jobs/crm/enrich_lead_job_test.rb`:
  - Calls service with correct lead
  - Returns early if lead not found
  - Re-raises `EnrichmentError` for Sidekiq retry
- [ ] Controller specs `test/controllers/contacts_controller_test.rb`:
  - Submission with honeypot field populated is rejected (calls `handle_spam`)
  - Submission under timestamp threshold is rejected
  - Valid submission succeeds
- [ ] RackAttack throttle test: 4th POST from same IP within 10 minutes returns 429
- [ ] System test `test/system/crm/lead_enrichment_test.rb`: enriched lead shows industry badge on kanban card and enrichment panel on detail view
- [ ] Edge cases covered:
  - `contact_email` is nil (skip, no job)
  - Hunter.io returns 429 (rate limit) — `EnrichmentError` raised, Sidekiq retries
  - Hunter.io returns malformed JSON — `EnrichmentError` raised
  - `enrichment_data` jsonb has unexpected keys — views use safe `&.dig` access
- [ ] Run: `bin/fast_test` — all passing

---

## Implementation Checklist

### Setup
- [ ] Feature flag created in Flipper: `crm_lead_enrichment`
- [ ] `HUNTER_IO_API_KEY` added to Heroku Config Vars (production + staging)
- [ ] Database migration written and reviewed: `enrichment_data jsonb`, `enrichment_raw jsonb`, `enrichment_status string`, `enrichment_fetched_at datetime`, index on `enrichment_status`

### Core Implementation — Spam Protection (ship first, no external dependency)
- [ ] `ContactsController`: add `invisible_captcha scope: :contact, on_spam: :handle_spam` and `handle_spam` private method
- [ ] `app/views/contacts/new.html.erb`: add `<%= invisible_captcha %>` inside form block
- [ ] `config/initializers/rack_attack.rb`: add `contact_form/ip` throttle block
- [ ] Verify `invisible_captcha` initializer settings are appropriate (`timestamp_threshold: 2`, `timestamp_enabled: true`)

### Core Implementation — Lead Enrichment (requires `HUNTER_IO_API_KEY`)
- [ ] Migration applied in development and reviewed against structure.sql
- [ ] `PERSONAL_EMAIL_DOMAINS` constant defined in `Crm::LeadEnrichmentService`
- [ ] `Crm::LeadEnrichmentService` implemented with `Result` struct and `EnrichmentError`
- [ ] `Crm::EnrichLeadJob` implemented with idempotency guard
- [ ] `CrmLead` after_commit callbacks added (feature-flag-gated)
- [ ] `CrmLeadAudit` writes for enrichment events (use `Crm::LeadAuditWriter.write`)

### Frontend
- [ ] Kanban card: industry badge added (conditional on enrichment_status == 'enriched')
- [ ] Lead detail show: Enrichment card added to left column (all four states handled)
- [ ] Contact form: `invisible_captcha` helper added
- [ ] Mobile/responsive: enrichment card collapses correctly on small viewport (Bootstrap col-md-4 handles this)

### Quality
- [ ] All tests written and passing (`bin/fast_test`)
- [ ] RuboCop clean (`bundle exec rubocop`)
- [ ] Brakeman clean (`bundle exec brakeman`)
- [ ] JS/CSS lint clean (`yarn lint`) — no JS changes expected
- [ ] Docs regenerated (`bin/generate_docs`)

### Release
- [ ] Spam protection can be deployed first (zero external dependency) — deploy ahead of enrichment if desired
- [ ] `crm_lead_enrichment` flag enabled for `admin@mellow.menu` user first; then rolled out platform-wide
- [ ] Migration is additive (new nullable/defaulted columns) — safe for zero-downtime deploy
- [ ] Monitor Sidekiq `:crm` queue depth after rollout to confirm jobs are processing cleanly
- [ ] Monitor Hunter.io API usage dashboard to track enrichment rate vs free tier limit (25/month free; upgrade if needed)

---

## Open Questions

1. **Hunter.io endpoint selection**: Hunter.io offers both a `/people/find` (person enrichment by email) and an `/email-finder` (find email by name+domain). We want `/people/find`. Confirm the exact response schema against the v2 API docs before implementation — field names in `enrichment_data` may need adjustment.
2. **Personal email domain denylist scope**: Initial list is the five most common personal providers. Should this be a database-backed config so it can be updated without a deploy? For v1, a frozen constant is fine; flag for v2 if the list grows.
3. **Re-enrichment strategy**: Currently re-enriches only when email changes. Should there be a manual "Re-enrich" button on the lead detail view for stale data? Deferred to v2.
4. **Hunter.io rate limits on free tier**: 25 enrichments/month free. At current lead volume this is fine. If lead volume exceeds ~200/month, upgrade to the Starter plan ($49/mo). Add monitoring note to Sidekiq job.
5. **Contact form name/restaurant fields**: The current `Contact` model only captures `email` and `message` — no name or restaurant name. Spec #27 (Lead Source Tracking) adds contact form → CRM ingestion. These two specs should be implemented together or sequentially (spam protection first, enrichment second, contact form → CRM ingestion from #27 third).

## References

- Hunter.io People Enrichment API v2: https://hunter.io/api-documentation/v2#people-finder
- `invisible_captcha` gem: https://github.com/markets/invisible_captcha
- Related spec: `docs/features/todo/backlog/27-lead-source-tracking.md` (contact form → CRM ingestion)
- Existing `rack_attack.rb`: `config/initializers/rack_attack.rb`
- Existing `invisible_captcha` initializer: `config/initializers/invisible_captcha.rb`
- CRM sales funnel spec (completed): `docs/features/completed/crm-sales-funnel.md`
