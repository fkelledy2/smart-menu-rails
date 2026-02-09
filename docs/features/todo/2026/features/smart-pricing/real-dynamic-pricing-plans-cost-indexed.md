# Real Dynamic Pricing Plans (Cost-Indexed, Price-Locked at Signup)

## � Related Specifications

- `cost-insights-and-pricing-model-publisher-admin-system.md`
- `heroku-cost-inventory-spaces-pipelines.md`

## �📋 Feature Overview

**Feature Name**: Real Dynamic Pricing Plans (Cost-Indexed, Price-Locked at Signup)

**Priority**: High

**Category**: Billing / Monetization / Finance Ops

**Estimated Effort**: Large (6-10 weeks for v1, depending on Stripe strategy + cost ingestion)

**Target Release**: 2026

## 🎯 Problem Statement

Current pricing plans are static and manually managed. Smart Menu has usage-variable costs (AI/OCR, compute, storage) and infra costs that can change meaningfully over time. Static pricing makes it harder to:

- Maintain consistent gross margins
- Scale support/staff headcount sustainably
- React to vendor price changes (OpenAI, infra)

## 🥅 Overall Goals

1. Provide detailed insights into the costs of running mellow.menu:
   - cloud costs (Heroku + add-ons across all environments)
   - third-party SaaS/API integrations (OpenAI, DeepL, Google Maps/Vision, Stripe fees, Sentry, storage, etc.)
2. Allow `admin && super_admin` to input **support/staff costs** per month.
3. Allow `admin && super_admin` to configure the desired **profit margin** (to fund growth).
4. Provide a review + publish workflow where `admin && super_admin` can:
   - review computed totals and derived plan prices
   - choose when to apply them
   - publish a new pricing model version that becomes the source of truth for new signups

## ✅ Proposal Summary

Implement **cost-indexed pricing** for Starter/Professional/Business/Enterprise such that:

- **New signup prices are computed from a versioned “pricing model”** driven by real running costs + target gross margin.
- **Prices are locked at the date of signup** for the lifetime of the subscription (until plan change/cancel).
- Customers are attached to a specific **pricing version** (cohort pricing).
- Public pricing pages show **current prices only**, while each customer sees **their own cohort price**.

This is not surge pricing. It is **versioned cost-based pricing**.

### Decisions (Confirmed)

- **Currencies**: Support **USD and EUR** (prices published per currency).
- **Stripe strategy**: Use **Stripe Price per pricing model version**.
- **Plan changes**: Default behavior is to move customers to the **current pricing model** on upgrade/downgrade, with an **admin/super_admin override** to keep the original cohort pricing when explicitly approved.

## 🧑‍💼 User Stories

### Customer

**As a** restaurant owner

**I want** stable subscription pricing after I sign up

**So that** I can budget and trust the platform long-term.

### Mellow Ops / Finance

**As a** Mellow operator

**I want** plan prices for new customers to automatically reflect our costs and required margin

**So that** we can scale responsibly without surprise pricing changes or ad hoc plan edits.

### Support / Admin

**As a** super admin

**I want** to inspect why a given customer pays a specific price

**So that** we can answer pricing questions quickly and consistently.

## 📐 Scope

### In scope (v1)

- Versioned pricing model entity and computation
- Price lock-in at signup (cohort pricing)
- Persisting “applied price” onto the customer subscription record
- Admin tooling to view current model + historical models + per-customer cohort
- Ability to manually publish a new pricing model version (initially)

### Explicitly out of scope (v1)

- Per-customer negotiated pricing (Enterprise contracts)
- Real-time per-request dynamic pricing
- Automated vendor invoice parsing (we can start with manual cost entry)
- Regionalized pricing (currency/geo)

## 🔒 Key Invariants

- **Existing customers never change price automatically.**
- **Price changes only occur on:**
  - plan upgrade/downgrade, OR
  - cancel + new subscription, OR
  - explicit contract renewal flow (enterprise)
- **Pricing models are immutable once published.** If a value is wrong, publish a new version.

## 🏗️ Current Architecture Notes (Observed)

- `Plan` contains plan limits and `pricePerMonth` plus `stripe_price_id_month`/`stripe_price_id_year`.
- `Userplan` ties user ↔ plan.
- Stripe plan changes occur via `UserplansController` and Stripe Billing Portal.
- There is an existing payments/orchestrator architecture; Stripe is present.

This feature will require deciding whether Stripe prices remain static per plan, or whether we create new Stripe prices per pricing model version.

## 🧩 Proposed Domain Model

### 1) PricingModel (versioned)

Represents the published cost snapshot + margin targets and computed plan prices.

**Conceptual attributes**:

- `version` (e.g. `2026_02`, unique)
- `effective_from` (date/time)
- `status` (draft, published, retired)
- `currency` (ISO code: `EUR` or `USD`)
- Cost inputs (totals or per-component):
  - `infra_base_monthly_cost`
  - `infra_variable_unit_costs` (json)
  - `ai_unit_costs` (json)
  - `support_cost_monthly`
  - `staff_growth_allocation_monthly`
- Profit/margin targets:
  - `target_gross_margin_pct`
  - optional: `floor_gross_margin_pct`
- Plan weighting/allocations:
  - `plan_weights` (json) OR explicit columns per plan
- Computed outputs:
  - `starter_price_cents_month`
  - `pro_price_cents_month`
  - `business_price_cents_month`
  - `enterprise_price_cents_month` (may be “call us”)

### 2) PricingModelPlanPrice (recommended normalized table)

Required for v1 because we support both USD and EUR and need explicit per-currency published prices.

- `pricing_model_id`
- `plan_id` (FK to `plans`)
- `interval` (`month` | `year`)
- `price_cents`
- `stripe_price_id` (optional; depends on strategy)

Note: `currency` should be stored on this row (not inferred) to keep pricing unambiguous.

### 3) AppliedPrice / Customer Cohort link

We need to persist which pricing model a customer is on, and what they pay.

Options:

- **Option A (minimal):** add fields to `userplans`:
  - `pricing_model_id`
  - `applied_price_cents_month`
  - `applied_currency`
  - `applied_interval`
  - `applied_stripe_price_id` (if using Stripe price-per-version)

Also add:

- `pricing_cohort_locked` (boolean) or `pricing_override_reason` (text)
- `pricing_override_by_user_id` (FK users) nullable
- `pricing_override_at` (datetime) nullable

- **Option B:** create `applied_plan_prices` table linked to `userplans` (more auditable).

## 💳 Stripe Integration Strategies

### Strategy 1 (selected): Stripe Price per Pricing Model Version

- For each published pricing model, create **new Stripe Price IDs** for Starter/Pro/Business.
- New customers subscribe using the Stripe Price ID for that model/version.
- Existing customers keep their existing Stripe subscription price.

Multi-currency:

- Each published pricing model version produces Stripe Prices for each:
  - plan (starter/pro/business)
  - interval (month/year)
  - currency (USD/EUR)

**Pros**:

- Source of truth remains Stripe for what is billed.
- Clean cohort isolation.
- No hacks required.

**Cons**:

- Stripe catalog grows over time.
- Requires admin tooling and robust mapping.

### Strategy 2 (not recommended unless needed): Single Stripe Price + internal invoice adjustments

- Keep one Stripe Price per plan.
- Use invoices, coupons, or metered adjustments to land the cohort price.

**Pros**: fewer Stripe objects.

**Cons**:

- Complexity and risk.
- Harder auditability.
- More customer confusion.

**Decision**: Use Strategy 1.

## 🧠 Pricing Engine

### Inputs

- Published `PricingModel` cost snapshot (manual entry v1)
- Target margin requirements
- Plan weights/allocations

### Outputs

- Price per plan per interval in cents
- (Optional) recommended plan limits adjustments (out of scope v1)

### Implementation

Create service object:

- `Pricing::ModelCompiler`
  - validates model completeness
  - computes plan prices deterministically
  - writes computed prices to `pricing_model_plan_prices`

And a selector:

- `Pricing::ModelResolver.current` returns latest `published` model by `effective_from`.

### Determinism and audit

- Computation must be deterministic and traceable.
- Store `inputs_json` and `outputs_json` on the pricing model for future explainability.

## 🧾 Signup and Plan Change Flow

### Registration (new customer)

1. Determine `current_pricing_model` (published, effective)
2. Determine selected plan (`Plan`)
3. Determine interval (month/year)
4. Determine currency (USD/EUR)
5. Resolve price record for plan+interval+currency
6. Create Stripe checkout session using the resolved `stripe_price_id`
6. Persist on success:
   - `user.plan = selected_plan`
   - `userplan.plan = selected_plan`
   - `userplan.pricing_model_id = current_pricing_model.id`
   - `userplan.applied_price_cents_*` and `applied_stripe_price_id`

### Upgrade/Downgrade

Default:

- On plan change, the customer moves to the **current pricing model** (current published version effective at the time of change).

Override:

- Allow an explicit admin/super_admin-approved override to keep the original cohort pricing model.
- Override must:
  - be recorded (who approved, when, reason)
  - be visible in admin tooling
  - not be possible via self-serve customer UI

## 🧑‍💻 Admin UX

### Pricing Model Admin Surface

- List pricing models:
  - version, effective_from, status
  - summary of computed prices
- Draft editor:
  - edit cost inputs, margin targets, plan weights
  - preview computed prices
- Publish action:
  - locks the model
  - (if Strategy 1) creates Stripe Prices for each plan/interval

### Cost Management / Visibility (Admin + Super Admin only)

Any UI/UX for viewing, editing, importing, or exporting **running cost** inputs (infra costs, vendor costs, cost snapshots, usage rollups) must be restricted to users who are:

- `admin: true` AND
- `super_admin: true`

Implementation note:

- Reuse the existing “Admin Area” gating pattern in the navbar (admin area is visible to `admin?`, and sensitive tools like impersonation are further gated by `super_admin?`).
- For cost tooling, require both predicates (do not allow `admin`-only access).
- Do **not** implement these screens inside `Madmin`. Admin cost tooling must follow the dedicated `Admin::` namespace approach used by the super-admin impersonation feature (separate controllers + views + routes).

### Customer View

- On `Userplan` billing page show:
  - current plan
  - “Pricing version: 2026_02”
  - monthly price
  - “Price locked since signup” copy

## 🗄️ Database Design (Rails migrations)

### Migration: `pricing_models`

- `version` string unique
- `status` integer enum (draft/published/retired)
- `effective_from` datetime
- `currency` string (`EUR` or `USD`)
- `inputs_json` jsonb
- `outputs_json` jsonb
- timestamps

Note: `inputs_json` must support infra cost totals that include **multiple environments** (see below).

### Migration: `pricing_model_plan_prices` (if using normalized table)

- `pricing_model_id` FK
- `plan_id` FK
- `interval` string
- `price_cents` integer
- `currency` string
- `stripe_price_id` string nullable
- unique index on `[pricing_model_id, plan_id, interval]`

Update uniqueness to include currency:

- unique index on `[pricing_model_id, plan_id, interval, currency]`

### Migration: add applied fields to `userplans`

- `pricing_model_id` FK nullable (until rollout)
- `applied_price_cents` integer
- `applied_currency` string
- `applied_interval` string
- `applied_stripe_price_id` string

### Migration: pricing override fields (optional v1 but recommended)

- `pricing_override_by_user_id` bigint
- `pricing_override_at` datetime
- `pricing_override_reason` text
- `pricing_override_keep_original_cohort` boolean default false

## 🧪 Test Plan

### Unit tests

- Pricing computation determinism
- Model resolver picks correct published model
- Model publish transitions are immutable

### Integration tests

- Signup attaches pricing_model + applied price
- Plan change moves to current pricing model (if chosen)
- Stripe mapping correctness (mocked)

### Security / fraud

- Only super admins can publish pricing models
- Ensure no pricing model fields are modifiable post-publish

## 📈 Observability

- Structured logs:
  - `pricing_model.published`
  - `pricing_model.price_compiled`
  - `billing.signup_pricing_applied`
- Admin audit table (optional v1): record who published pricing model

## 💱 Currency and FX Policy (USD/EUR)

Pricing is published **per currency**, not converted on the fly.

- Do not compute EUR by converting USD (or vice versa) at runtime.
- Each `pricing_model_plan_price` row includes an explicit `currency`.
- UI currency selection should be deterministic and stored on the customer’s subscription (`userplans.applied_currency`).

Recommended v1 currency resolution order:

1. If a restaurant has a `country` and it maps to a currency, use that.
2. Else, if Stripe customer has a default currency, use that.
3. Else default to EUR.

Decision (v1): Use **Option A** (country-based) as the primary source of truth.

- Currency is selected from the restaurant’s `country` (or equivalent stored field) at the time the subscription/plan change is initiated.
- The selected currency is persisted onto the subscription record (`userplans.applied_currency`) and never changes automatically.

Note: if currency is user-selectable at signup, store it immediately and treat it as part of the pricing cohort identity.

## 🧾 Stripe Naming and Metadata Conventions

To keep Stripe manageable as prices proliferate by version/currency/interval, enforce conventions.

### Stripe Product

Keep a single Stripe Product per plan (Starter/Professional/Business) and create new Prices under that product.

### Stripe Price

When publishing a pricing model, create Prices with:

- `currency`: `eur` or `usd`
- `recurring.interval`: `month` or `year`
- `unit_amount`: cents
- `nickname` (suggested):
  - `starter_2026_02_eur_month`
  - `pro_2026_02_usd_year`

Attach metadata (minimum):

- `pricing_model_version`: `2026_02`
- `plan_key`: `plan.starter.key`
- `currency`: `EUR`
- `interval`: `month`

This makes it possible to trace billing issues in Stripe without database access.

## 🛡️ Admin Override (Keep Original Cohort) — Auditability

If a plan change is executed with “keep original cohort pricing”, persist an explicit audit trail:

- `pricing_override_keep_original_cohort: true`
- `pricing_override_by_user_id`
- `pricing_override_at`
- `pricing_override_reason`

Enforcement:

- The override must only be settable by `admin`/`super_admin` actions.
- Any self-serve customer plan change must default to “move to current pricing model”.

## �� Rollout Plan

### Phase 0: Schema + admin-only model (no customer impact)

- Add tables
- Add admin UI to create/publish models

### Phase 1: New signups only

- New signup flow uses current pricing model
- Existing customers unchanged

### Phase 2: Plan changes

- Decide and implement cohort behavior on plan change

## ⚠️ Risks and Mitigations

- **Customer confusion (“why is my friend paying less?”)**
  - Never show historical prices publicly
  - Show only “Your pricing version” in account UI
- **Stripe catalog explosion**
  - Use version naming conventions; optionally retire old prices
- **Legal/compliance**
  - Ensure T&C language: price locked at signup; changes only on plan change

## 🧱 Infrastructure Cost Modeling (Heroku + Environments)

Heroku costs must account for the full system required to operate mellow.menu, not just production.

Decision (environment discovery): Use **Heroku Spaces** as the authoritative grouping. The `smart-menu` space is the primary space to inventory when computing infra costs.

Minimum environments to model in v1:

- `production`
- `staging`
- `development`

Also support optional ephemeral environments:

- feature test instances / review apps / temporary customer sandboxes

Recommended representation (in `inputs_json` or a normalized table in a follow-up):

- `infra_costs`:
  - `production`: { web_dynos, worker_dynos, postgres_plan, redis_plan, addons: [], estimated_monthly_cost_cents }
  - `staging`: { ... }
  - `development`: { ... }
  - `ephemeral`: {
      assumed_concurrent_instances,
      avg_lifetime_days,
      per_instance_monthly_cost_cents,
      estimated_monthly_cost_cents
    }

Allocation policy (v1 default):

- Total monthly infra cost = sum across envs.
- Allocate total monthly infra cost into plan pricing via the pricing model’s plan weights.

Heroku extraction notes:

- Use the Heroku Platform API to list all apps in the `smart-menu` space.
- For each app:
  - read formation (dyno types/count)
  - read add-ons (Postgres/Redis/etc. plans)
  - (optional) read pipeline + stage metadata if available
- Classify each app into `production` / `staging` / `development` / `ephemeral` based on pipeline stage and/or naming conventions.

## ✅ Acceptance Criteria

- [ ] Admin can create a draft pricing model and preview computed prices
- [ ] Admin can publish pricing model, making it immutable
- [ ] New signups are billed using the pricing model active at signup time
- [ ] Userplan stores `pricing_model_id` and applied price fields
- [ ] UI shows customer their locked price and pricing version
- [ ] Historical cohorts remain billed correctly after new models published

## ✅ Implementation Checklist

- [ ] Add/confirm data model for `pricing_models` and `pricing_model_plan_prices` (USD/EUR, monthly/yearly, Stripe price id per version)
- [ ] Add applied pricing fields and override audit fields to `userplans`
- [ ] Implement pricing model compilation service (`Pricing::ModelCompiler`) and resolver (`Pricing::ModelResolver`)
- [ ] Implement Stripe price publication for `(plan, interval, currency, version)`
- [ ] Update signup flow to select currency via Restaurant `country`, resolve current pricing model, and subscribe via versioned Stripe Price
- [ ] Update plan-change flow to default to current pricing model; implement admin/super_admin override to keep original cohort with audit trail
- [ ] Implement admin-only UI entry points (in `Admin::` namespace, not `Madmin`) to preview/publish pricing model versions
- [ ] Add observability logs for compile/publish/apply events
- [ ] Write extensive unit tests for:
  - [ ] pricing compilation determinism
  - [ ] currency selection rules (country → currency)
  - [ ] Stripe price mapping and persistence
  - [ ] plan-change cohort default/override behavior
- [ ] Write extensive system tests for:
  - [ ] pricing version shown to customer
  - [ ] new signup uses latest published model
  - [ ] plan change switches cohort by default
  - [ ] admin override keeps cohort when approved

## 🧾 Definition of Done

- [ ] All checklist items completed
- [ ] Extensive unit tests and system tests implemented and **all passing**
- [ ] No access to pricing publication tooling for non `admin && super_admin`
- [ ] No regressions in billing flows (signup, plan change, cancellation)
- [ ] Documentation updated and cross-references accurate

---

## ❓ Open Questions (Need Answers)

### Product / Policy

1. Are prices allowed to differ by region (EU vs US) in future? If yes, do we capture `country` at signup and bind it to the cohort?
2. What is the v1 rule for currency selection?
   - based on billing country,
   - explicit customer selection,
   - restaurant country,
   - or Stripe customer default currency?
3. How do we treat Enterprise:
   - always “Contact us” (no self-serve), or
   - computed minimum price with negotiation on top?
4. Should annual billing be:
   - derived by discount (e.g. 2 months free), or
   - computed independently from annual cost assumptions?

### Finance / Cost Model

6. What cost inputs are mandatory for v1?
   - Heroku, Postgres, Redis, email, storage, monitoring, OpenAI, etc.
7. How do we allocate shared costs to plans?
   - weights by plan tier, active restaurants, usage, or fixed ratios?
8. Target gross margin: single global % or per-plan margin targets?
9. How do we incorporate support load (tickets per customer) and staff growth?
   - fixed allocation per customer tier, or weighted by plan?

### Engineering / Stripe

5. Where does “subscription” live today?
    - Is the authoritative subscription record on `RestaurantSubscription` or elsewhere?
6. Do we need to support mid-cycle proration behavior for plan changes?
7. How do we backfill existing customers into a “legacy pricing model” record?
8. What is the Stripe naming convention for price objects? (Recommended includes version + currency + interval)

### Legal / UX

9. Required copy on pricing page:
    - “Prices are fixed at signup and never change unless you upgrade.” OK?
10. Admin override policy:
    - Who can approve keeping original cohort pricing on plan change?
    - Is an audit trail legally required / desired for internal governance?

---

**Created**: February 9, 2026

**Status**: Draft
