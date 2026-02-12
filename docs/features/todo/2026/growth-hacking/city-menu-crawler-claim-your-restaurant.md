# City Menu Crawler + “Claim Your Restaurant” Growth Engine — Technical Specification

## 📋 Feature Overview

**Feature Name**: City Menu Crawler + “Claim Your Restaurant” Growth Engine

**Priority**: High

**Category**: Growth Hacking / Acquisition / SEO / Ops

**Estimated Effort**: Large (8–16 weeks depending on how automated crawling + diff + claim verification are in v1)

**Target Release**: 2026

## 🥅 Overall Goals

1. Build a legally-safe system to discover publicly available menus and pre-provision “draft/unclaimed” restaurant profiles.
2. Create a defensible funnel: **“Claim your restaurant on mellow.menu”**.
3. Keep humans in control for any publishing decisions and avoid “blind scraping”.
4. Ensure a clean separation between:
   - **unclaimed preview mode** (minimal transformation, heavy disclaimers)
   - **claimed official mode** (full management + optional enrichments)

## 🔗 Related Specifications / References

- Admin pattern (separate Admin namespace, super admin gating):
  - `../features/super-admin-impersonation-act-as-user.md`
- Stripe/payments infra (global payments):
  - (existing payments implementation in `app/controllers/payments/*`)
- Smart pricing docs (optional, for future “pricing by city density” strategies):
  - `../features/smart-pricing/`

## ✅ Non-Negotiable Constraints (Legal + Product)

### Human-in-the-loop

- No city crawl results are automatically published.
- A `admin && super_admin` must explicitly approve provisioning and/or publishing.

### Respect source policies

- Respect `robots.txt`.
- Respect `noindex` / `nosnippet`.
- Only crawl sources that are:
  - first-party restaurant websites
  - restaurant-hosted PDFs
- Do not crawl:
  - delivery platforms
  - POS vendor pages
  - aggregator directories (unless explicitly licensed)

### Preview-only for unclaimed restaurants

- Unclaimed restaurants must not be represented as “official”.
- UI must include a prominent banner:
  - “This is an auto-generated preview based on publicly available information. Claim this restaurant to manage and publish the official menu.”

### Removal request (fast)

- Every unclaimed page must include a “Claim or request removal” link.
- Removal requests must:
  - unpublish immediately
  - be logged
  - be reviewed asynchronously

### AI guardrails (pre-claim)

Allowed (normalize only):

- price parsing
- name cleanup
- description cleanup (grammar/whitespace) only
- category grouping

Disallowed (pre-claim):

- new/expanded marketing copy
- translations
- AI image generation
- tone/brand voice rewriting

Normalize-only (v1 decisions):

- Deduplicate items
- Fix casing
- Parse prices/currencies
- Strip junk characters / whitespace cleanup
- Infer section headings

## 📐 Scope

### In scope (v1)

- Admin-only “Crawl a City” UI (Admin namespace, not Madmin)
- Discovery queue of candidate restaurants/menus
- Manual approval workflow
- Provision unclaimed restaurant + menu under `admin@mellow.menu`
- Minimal AI normalization mode
- Change detection (detect → review → optionally re-import)
- Claim flow including **Stripe KYC** step to unlock payments/ordering

Discovery specifics (v1 decisions):

- City selection is done by a **Google Places** city lookup (e.g. “Budapest”, “Paris”, “Prague”) to lock in a canonical target.
- Venue discovery is done via **Google Places** search using **place types only**.
- Venue types to include (v1):
  - `restaurant`
  - `bar`
  - `wine_bar`
  - `whiskey_bar`
- Dedupe key is `google_place_id`.
- Menu discovery should prefer publicly available **PDF menus**.
- Restaurants without a first-party website should be skipped in v1.

### Out of scope (v1)

- Full automation of publishing
- Bulk crawling without approval
- Fully automated legal review
- Scraping restricted/paid sources

## 🧑‍💻 Roles / Permissions

### Super admin (required)

All cost-sensitive and legally sensitive operations:

- Crawl city
- Approve/reject discovered restaurants
- Provision unclaimed restaurants
- Publish/unpublish previews
- Configure source rules/blacklists

Authorization rule:

- `current_user.admin? && current_user.super_admin?`

## 🏗️ High-Level Architecture

### Flow 1: City discovery

1. Super admin chooses a City
2. System runs `CityDiscoveryJob`
3. Job produces a list of `DiscoveredRestaurant` records
4. Admin reviews queue and selectively approves

### Flow 2: Provisioning (approved imports)

1. Admin approves a `DiscoveredRestaurant`
2. System runs `ProvisionUnclaimedRestaurantJob`
3. Creates Restaurant + Menu + MenuSections + MenuItems (minimal)
4. Marks restaurant status = `unclaimed`
5. Enables preview visibility + disables ordering/payments

### Flow 3: Change detection

1. Scheduled `MenuChangeDetectionJob` checks sources (HEAD, ETag/hash)
2. If change detected:
   - for unclaimed: goes into admin review queue
   - for claimed: notify owner and allow manual sync with diff

### Flow 4: Claim your restaurant

1. Restaurant owner starts claim
2. Soft verification (domain/email/DNS/etc.) unlocks editing
3. Stripe KYC (Connect) unlocks payments + ordering + removes preview watermark

## 🗄️ Data Model

### 1) Discovered restaurants and menu sources

#### Table: `discovered_restaurants`

- `city` string (or `city_id` FK)
- `name` string
- `source_url` string
- `menu_source_type` enum: `html`, `pdf`
- `confidence_score` decimal
- `status` enum: `pending`, `approved`, `rejected`, `blacklisted`
- `discovered_at` datetime
- `notes` text
- `metadata` jsonb (optional: extracted address candidate, phone, etc.)

Indexes:

- index on `[city, status, discovered_at]`
- unique-ish index on `[source_url]` (or allow duplicates but dedupe in UI)

#### Table: `menu_sources`

Normalize “where did this menu come from?”

- `restaurant_id` (unclaimed or claimed)
- `source_url`
- `source_type` enum: `html`, `pdf`
- `last_checked_at`
- `last_fingerprint` string (hash)
- `etag` string nullable
- `last_modified` datetime nullable
- `status` enum: `active`, `disabled`

### 2) Restaurant claim state

Add fields to `restaurants`:

- `claim_status` enum: `unclaimed`, `soft_claimed`, `claimed`, `verified`
- `provisioned_by` enum: `system`, `owner`
- `source_url` string nullable
- `preview_enabled` boolean default false
- `preview_published_at` datetime nullable
- `preview_indexable` boolean default false
- `ordering_enabled` boolean default false
- `payments_enabled` boolean default false

Add fields to `restaurants` (v1 decisions):

- `google_place_id` string, unique (copied from Places and treated as the authoritative identity)

### 3) Claim requests + audit

#### Table: `restaurant_claim_requests`

- `restaurant_id`
- `initiated_by_user_id` nullable
- `status` enum: `started`, `soft_verified`, `stripe_kyc_started`, `stripe_kyc_completed`, `approved`, `rejected`
- `verification_method` enum: `email_domain`, `dns_txt`, `gmb`, `manual_upload`
- `verified_at` datetime
- `review_notes` text

### 4) Removal requests

#### Table: `restaurant_removal_requests`

- `restaurant_id`
- `requested_by_email` string
- `source` enum: `public_page`, `email`
- `status` enum: `received`, `actioned_unpublished`, `resolved`
- `reason` text

## 🤖 AI Normalization Mode

Introduce a per-menu/per-import flag:

- `ai_mode` enum:
  - `normalize_only` (pre-claim default)
  - `full_enrich` (post-claim optional)

In `normalize_only`, AI must not introduce new claims, tone, or marketing.

## 🌐 Crawling + Extraction

### Discovery strategy (safe)

- Use Google Places to identify venues in the chosen city.
- Candidate sources must be whitelisted by rule.

Menu discovery strategies (v1 decisions):

- Use both:
  - Place details (e.g. website)
  - Follow-on discovery on the first-party restaurant website domain
- Additionally allow a Google search fallback to find publicly available menu PDFs (bounded and rate-limited).

### Extraction

- HTML menus: parse structured text, prices, headings.
- PDF menus: use existing OCR pipeline where applicable.

Menu PDF corpus storage (v1 decisions):

- Always store the latest discovered menu PDF/file in S3 via ActiveStorage.
- Goal is to build a corpus for menu import/model development and tuning.

### Robots/noindex enforcement

- Store crawl decision evidence:
  - robots allowed/blocked
  - noindex/nosnippet found

## 🔁 Change Detection

### Fingerprinting

- For HTML: canonicalized text + hash
- For PDFs: content hash

### Workflow

- detect change → create `menu_source_change` record → human review → import

## 🧑‍💻 Admin UI (Admin Namespace, not Madmin)

All admin screens require `admin && super_admin`.

### Screen 1: Crawl City

- Select city
- Start crawl (enqueues job)
- Show current crawl status

### Screen 2: Discovery Queue

- Filter by status
- Inspect details
- Approve / reject / blacklist

### Screen 3: Approved Imports

- Show provisioning progress
- Link to unclaimed restaurant preview

Preview publish gate (v1 decisions):

- Approval/provisioning creates `Restaurant + Menu` but does not make the preview indexable.
- A super admin must explicitly “Publish preview” which sets:
  - `preview_enabled = true`
  - `preview_published_at = Time.current`
  - `preview_indexable` remains false by default

### Screen 4: Source Rules

- Whitelist rules
- Blacklist domains
- User-agent policy

### Screen 5: Change Detection Queue

- Show diffs
- Approve re-import

## 🧾 Claim Flow (Stripe KYC)

### Step 1: Soft claim (v1)

Allowed methods (pick at least one):

- email domain verification
- DNS TXT record
- Google Business Profile link
- manual document upload (admin review)

Unlocks:

- editing
- preview publish controls

### Step 2: Hard claim (Stripe KYC)

Required for:

- enabling ordering
- enabling payments
- removing preview watermark

Implementation notes:

- Stripe Connect onboarding + account verification
- Stripe Connect mode (v1 decision): Standard
- Require entity name + address consistency checks

Soft verification (v1 decision):

- Any method is acceptable for v1; implementation can start with the simplest workable flow and expand.

## 🧪 Test Plan

### Unit tests

- crawler respects robots/noindex
- domain blacklisting
- provisioning creates correct records
- AI mode guardrails enforced
- claim status transitions

### System tests

- admin crawl → discovery queue → approve → restaurant provisioned
- public preview shows correct disclaimers
- removal request unpublishes immediately
- claim flow gates editing and payment enablement

## ✅ Implementation Checklist

### Legal + safety

- [x] robots.txt compliance (`MenuDiscovery::RobotsTxtChecker` service, integrated into CityDiscovery, WebsiteMenuFinder, WebsiteContactExtractor, DeepDiveJob)
- [x] noindex/nosnippet compliance (detection in WebsiteMenuFinder + WebsiteContactExtractor, conditional meta tag in `_head.html.erb`, X-Robots-Tag header)
- [x] source whitelist + domain blacklist (`CrawlSourceRule` model + admin CRUD + integrated into CityDiscovery)
- [x] removal request flow (immediate unpublish) (`RestaurantRemovalRequest` model, public form, admin management, immediate `preview_enabled = false`)

### Data model

- [x] migrations for discovered restaurants + menu sources + claim requests + removal requests
- [x] restaurant fields for claim/provision state (`claim_status`, `provisioned_by`, `source_url`, `preview_enabled`, `preview_published_at`, `preview_indexable`, `ordering_enabled`, `payments_enabled`, `google_place_id`)

### Crawling + extraction

- [x] discovery implementation (Google Places city lookup + venue search by place types) (`GooglePlaces::CityDiscovery`, `CityDiscoveryJob`)
- [x] menu discovery implementation (Place details + website crawl + bounded Google search fallback) (`MenuDiscovery::WebsiteMenuFinder`, `MenuDiscovery::WebsiteContactExtractor`)
- [x] extraction implementation (html/pdf) (`PdfMenuProcessor` with venue-type-aware prompts for wine bars, whiskey bars, bars, restaurants)
- [x] store crawl evidence (robots/noindex) (stored in `discovered_restaurants.metadata['crawl_evidence']`)
- [x] always store latest PDF/file in ActiveStorage (S3 in production) (`MenuSource` with `latest_file` attachment)

### Jobs

- [x] `CityDiscoveryJob`
- [x] `PdfMenuExtractionJob` (existing OCR pipeline, extended for drink-focused menus)
- [x] `ProvisionUnclaimedRestaurantJob`
- [x] `MenuChangeDetectionJob` (existing)
- [ ] `MenuDiffJob` (Phase 2 — diff display for change detection review)

### Admin UI (Admin namespace)

- [x] Crawl City (`Admin::CityCrawlsController`)
- [x] Discovery Queue (`Admin::DiscoveredRestaurantsController` — index with filters, bulk actions, show with detail)
- [x] Approved Imports (`approved_imports` action on DiscoveredRestaurantsController — provisioning status, preview controls)
- [x] Publish preview (explicit action; defaults to noindex) (`publish_preview` action)
- [x] Source Rules (`Admin::CrawlSourceRulesController` — CRUD for blacklist/whitelist rules)
- [x] Change Detection Queue (`Admin::MenuSourceChangeReviewsController` — existing)
- [x] Claim Requests (`Admin::RestaurantClaimRequestsController` — approve/reject)
- [x] Removal Requests (`Admin::RestaurantRemovalRequestsController` — unpublish/resolve)

### Claim flow

- [x] Soft claim verification method(s) (`RestaurantClaimRequest` model with email_domain, dns_txt, gmb, manual_upload methods; public claim form)
- [x] Stripe KYC integration step (existing `Payments::StripeConnectController` + return handler enables payments/ordering and upgrades claim_status)
- [x] Gate payments/ordering behind hard claim (`OrderingGate` concern in `OrdrsController`, `ordering_enabled`/`payments_enabled` flags)

### Public-facing preview UX

- [x] "Claim this restaurant" + "Request removal" banner on unclaimed smartmenu pages (`_showMenuBanner.erb` — shows for any `@restaurant.unclaimed?` when no `current_user`)
- [x] Session ID blank fix — `safe_session_id` helper in `SmartmenusController` prevents `RecordInvalid` for new visitors (Rails cookie store returns nil `session.id` on first request)
- [x] Claim link routes to nested claim/removal request forms (`new_restaurant_claim_request_path`, `new_restaurant_removal_request_path`)
- [x] Post-registration redirect back to claim flow — session stores `claim_restaurant_id` on form visit, `after_sign_in_path_for` / `after_sign_up_path_for` redirect back

### Restaurant management (super_admin)

- [x] Publish/Unpublish preview toggle in Quick Actions panel (`_details_2025.html.erb` — matches Active/Inactive pill style, 50/50 horizontal layout)
- [x] `RestaurantsController#publish_preview` action — toggles `preview_enabled`, creates `Smartmenu` records for all active menus on publish
- [x] Super admin bypasses onboarding-blocked checks on unclaimed restaurants (subscription, employees, etc.)
- [x] Route: `PATCH /restaurants/:id/publish_preview`
- [x] Unpublish sets `preview_indexable = false` (`RestaurantsController#publish_preview` and bulk unpublish)
- [x] Bulk publish/unpublish from admin discovery queue (`bulk_update` action with `publish_preview` / `unpublish_preview` operations)

### AI guardrails

- [x] `ai_mode` enum on `OcrMenuImport` (`normalize_only` / `full_enrich`)
- [x] Auto-set `ai_mode` based on restaurant claim_status in controller
- [x] `OcrMenuImportPolisherJob` guards LLM description generation and image prompt generation behind `normalize_only` check

### Testing

- [x] Unit tests for models: `RestaurantClaimRequestTest`, `RestaurantRemovalRequestTest`, `CrawlSourceRuleTest`, `OcrMenuImportAiModeTest`, `RestaurantClaimStatusTest`
- [x] Unit tests for services: `RobotsTxtCheckerTest`, `PdfMenuProcessorVenueContextTest`, `ImportToMenuItemtypeTest`
- [x] Unit tests for concerns: `OrderingGateTest` (includes `current_user` stub for super_admin bypass)
- [x] System tests: `DiscoveryApprovalFlowTest` (3 tests), `ClaimAndRemovalFlowTest` (4 tests) — end-to-end approval, claim, removal, resolve flows
- [x] All unit tests passing (3549 runs, 10080 assertions, 0 failures, 0 errors)

## 🧾 Definition of Done

- [x] All admin screens are `Admin::` only and gated to `admin && super_admin`
- [x] No blind publishing; all provisioning/publishing requires explicit admin approval
- [x] Robust removal/unpublish capability
- [x] AI guardrails enforced pre-claim
- [x] Public URL shape is `/smartmenus/:slug` (backed by `Smartmenu.slug`) and includes banner/watermark for unclaimed previews
- [x] Unclaimed previews are `noindex` by default with an explicit admin option to make them indexable
- [x] All checklist items completed
- [x] System tests (end-to-end approval + claim flow) — 7 tests, 51 assertions, 0 failures
- [x] Dedicated claim landing page (nested claim/removal request forms)
- [x] Post-claim redirect flow back to the specific restaurant

## ✅ Phase 2 — Completed

1. **Dedicated claim landing page** — ✅ Nested claim/removal request forms with verification method selection
2. **Post-registration redirect** — ✅ Session-based redirect after sign-up/sign-in back to claim form
3. **MenuDiffJob** — ✅ Full diff pipeline with color-coded admin review UI
4. **Bulk publish/unpublish** — ✅ Admin discovery queue dropdown with publish/unpublish operations
5. **Unpublish cleanup** — ✅ Sets `preview_indexable = false` on unpublish
6. **System tests** — ✅ 7 tests covering discovery approval, claim submission, admin claim approval, removal request, admin removal resolve
7. **Claim verification UX** — ✅ Manual admin review flow (v1), model supports email_domain/dns_txt/gmb/manual_upload methods
8. **Restaurant.smartmenus association** — ✅ Added missing `has_many :smartmenus` for approved_imports view

---

**Created**: February 9, 2026

**Last Updated**: February 13, 2026

**Status**: ✅ Complete — All Phase 1 and Phase 2 items delivered. Core infrastructure, public preview UX, claim flow, admin review, bulk operations, change detection, and system tests all in place.
