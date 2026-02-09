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

## 📐 Scope

### In scope (v1)

- Admin-only “Crawl a City” UI (Admin namespace, not Madmin)
- Discovery queue of candidate restaurants/menus
- Manual approval workflow
- Provision unclaimed restaurant + menu under `admin@mellow.menu`
- Minimal AI normalization mode
- Change detection (detect → review → optionally re-import)
- Claim flow including **Stripe KYC** step to unlock payments/ordering

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
- `preview_enabled` boolean default true
- `ordering_enabled` boolean default false
- `payments_enabled` boolean default false

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

- Use search APIs / curated seed lists rather than brute-force crawling.
- Candidate sources must be whitelisted by rule.

### Extraction

- HTML menus: parse structured text, prices, headings.
- PDF menus: use existing OCR pipeline where applicable.

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
- Require entity name + address consistency checks

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

- [ ] robots.txt compliance
- [ ] noindex/nosnippet compliance
- [ ] source whitelist + domain blacklist
- [ ] removal request flow (immediate unpublish)

### Data model

- [ ] migrations for discovered restaurants + menu sources + claim requests + removal requests
- [ ] restaurant fields for claim/provision state

### Jobs

- [ ] `CityDiscoveryJob`
- [ ] `MenuExtractionJob`
- [ ] `ProvisionUnclaimedRestaurantJob`
- [ ] `MenuChangeDetectionJob`
- [ ] `MenuDiffJob`

### Admin UI (Admin namespace)

- [ ] Crawl City
- [ ] Discovery Queue
- [ ] Approved Imports
- [ ] Source Rules
- [ ] Change Detection Queue

### Claim flow

- [ ] Soft claim verification method(s)
- [ ] Stripe KYC integration step
- [ ] Gate payments/ordering behind hard claim

### Testing

- [ ] Extensive unit tests (crawler, extraction, provisioning, claim)
- [ ] Extensive system tests (end-to-end approval + claim)
- [ ] All tests passing

## 🧾 Definition of Done

- [ ] All checklist items completed
- [ ] Extensive unit tests and system tests implemented and **all passing**
- [ ] All admin screens are `Admin::` only and gated to `admin && super_admin`
- [ ] No blind publishing; all provisioning/publishing requires explicit admin approval
- [ ] Robust removal/unpublish capability
- [ ] AI guardrails enforced pre-claim

---

**Created**: February 9, 2026

**Status**: Draft
