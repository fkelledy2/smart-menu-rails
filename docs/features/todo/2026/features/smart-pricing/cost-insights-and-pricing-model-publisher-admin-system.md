# Cost Insights + Pricing Model Publisher (Admin System) — Technical Specification

## 📋 Feature Overview

**Feature Name**: Cost Insights + Pricing Model Publisher (Admin System)

**Priority**: High (enables cost-indexed dynamic plan pricing)

**Category**: Admin / Finance Ops / Monetization

**Estimated Effort**: Large (8–14 weeks depending on how much is automated vs manually entered in v1)

**Target Release**: 2026

## 🔗 Related Specifications

This spec composes the following docs and should not conflict with them:

- `real-dynamic-pricing-plans-cost-indexed.md`
- `heroku-cost-inventory-spaces-pipelines.md`

Cross-reference note:

- This document defines the **admin workflows**, **schema**, and **jobs** that produce publishable pricing models.
- `real-dynamic-pricing-plans-cost-indexed.md` defines how published models are applied to signups and plan changes.
- `heroku-cost-inventory-spaces-pipelines.md` defines the Heroku/cloud cost ingestion portion.

## 🥅 Overall Goals (Source of Truth)

1. Have detailed insights on the costs involved in running mellow.menu:
   - cloud costs (Heroku + add-ons across envs)
   - third-party SaaS/API integrations (OpenAI, DeepL, Google Maps/Vision, Stripe fees, Sentry, storage, etc.)
2. Allow `admin && super_admin` to input support/staff costs per month.
3. Allow `admin && super_admin` to configure desired profit margin to fund growth.
4. Allow `admin && super_admin` to review computed totals and choose when to apply them to pricing plans by publishing a new pricing model.

## ✅ Non-Negotiable Constraints

- All admin screens for this system must be implemented under a dedicated `Admin::` namespace, not `Madmin`.
- Any UI/UX for viewing, editing, importing, exporting costs or publishing pricing models is visible only to users who are:
  - `admin: true` AND
  - `super_admin: true`
- Published pricing models are immutable.
- Customer prices are price-locked at signup. Plan changes default to current model (with explicit super-admin override to keep original cohort).

## 📐 Scope

### In scope (v1)

- Admin UI to:
  - view cost insights (cloud + vendor + staff/support)
  - enter monthly staff/support costs
  - configure target gross margin
  - preview computed totals and resulting plan prices (USD/EUR)
  - publish a pricing model version
- Data model for:
  - vendor usage rollups (where measurable)
  - monthly cost snapshots (manual or ingested)
  - pricing models and per-plan prices
- Background jobs to:
  - ingest usage where feasible (DeepL usage API, internal metering for OpenAI/Vision)
  - import Heroku inventory snapshots (Space + Pipelines)
  - compute monthly rollups

### Out of scope (v1)

- Fully automated invoice ingestion for all vendors
- Regional pricing beyond USD/EUR
- Per-customer negotiated pricing engine

## 🧱 System Architecture

This system is a pipeline:

1. **Collect** usage metrics (daily) for variable-cost vendors (OpenAI, DeepL, Vision, Stripe fees).
2. **Collect** infra inventory (daily) for Heroku, and produce monthly infra cost rollups.
3. **Record** monthly staff/support costs.
4. **Compile** a `PricingModel` (cost snapshot + margin policy + weights) → per-plan prices.
5. **Publish** the pricing model (creates Stripe Prices per plan/currency/interval).
6. **Apply** the model to new signups; plan changes default to latest model.

## 🗂️ Data Model

### A) Usage metering (daily)

#### Table: `external_service_daily_usages`

Stores normalized daily usage counts.

- `date` (date, required)
- `service` (string, required) examples:
  - `openai`
  - `deepl`
  - `google_vision`
  - `google_maps`
  - `stripe`
  - `sentry`
  - `aws_s3`
- `dimension` (string, required)
  - e.g. `dall-e-3:1024x1024:standard`, `whisper-1`, `vision:text_detection`, `maps:js_load`, `stripe:fees`
- `units` (decimal or bigint; recommended decimal for flexibility)
  - e.g. `characters`, `seconds`, `images`, `requests`, `usd_cents`
- `unit_type` (string)
- `restaurant_id` bigint nullable (store when attribution is possible)
- `metadata` jsonb (optional)
- timestamps

Indexes:

- unique index: `[date, service, dimension, restaurant_id]`
- index: `[service, date]`

### B) Vendor cost inputs (monthly)

#### Table: `external_service_monthly_costs`

Stores monthly cost totals, which can be either:

- manually entered (v1)
- ingested from vendor billing exports (v2)

- `month` (date, first-of-month)
- `service` (string)
- `currency` (`USD`/`EUR`)
- `amount_cents` (integer)
- `source` (enum: `manual`, `api_ingest`, `csv_import`)
- `notes` text
- `evidence` jsonb (optional: invoice id, url)
- `created_by_user_id`, `updated_by_user_id`
- timestamps

Indexes:

- unique index: `[month, service, currency]`

### C) Staff/support costs (monthly)

#### Table: `staff_cost_snapshots`

- `month`
- `currency` (`USD`/`EUR`)
- `support_cost_cents`
- `staff_cost_cents`
- `other_ops_cost_cents` (optional)
- `notes`
- `created_by_user_id`, `updated_by_user_id`
- timestamps

Indexes:

- unique index: `[month, currency]`

### D) Profit margin configuration

#### Table: `profit_margin_policies`

Defines desired gross margin targets.

- `key` string unique (e.g. `default`)
- `target_gross_margin_pct` decimal(5,2)
- `floor_gross_margin_pct` decimal(5,2) nullable
- `status` enum: `active`, `inactive`
- `created_by_user_id`
- timestamps

### E) Pricing model publication

Use the entities defined in `real-dynamic-pricing-plans-cost-indexed.md`:

- `pricing_models`
- `pricing_model_plan_prices`
- applied pricing fields on `userplans`

This admin system will create and publish `pricing_models`.

## 🧮 Computation Model

### Monthly “total running cost”

For a given month and currency:

- `infra_cost_total` (Heroku env rollups; see Heroku spec)
- `vendor_cost_total` (sum of `external_service_monthly_costs`)
- `staff_support_total` (from `staff_cost_snapshots`)

Then:

- `total_cost = infra_cost_total + vendor_cost_total + staff_support_total`

### Margin and price derivation

Given:

- `total_cost`
- `target_gross_margin_pct`

Compute required revenue:

- `required_revenue = total_cost / (1 - target_margin)`

Allocate required revenue into plan prices using plan weights.

Implementation should be deterministic:

- store all inputs and outputs on the pricing model (`inputs_json`, `outputs_json`).

## 🧑‍💻 Admin UI (Admin Namespace)

All pages are `Admin::` and gated to `admin && super_admin`.

### Screen 1: Cost Insights Dashboard

Purpose: one place to view the full cost picture.

- Month selector
- Currency selector (USD/EUR)
- Cards:
  - Infra (Heroku) total + env breakdown
  - Vendor costs total + top services
  - Staff/support total
  - Total cost
  - Current active margin policy

### Screen 2: Vendor Costs (Monthly)

- Table of services by month
- Inline edit / create
- Notes + evidence

### Screen 3: Staff/Support Costs (Monthly)

- Input support cost
- Input staff cost
- Optional other ops

### Screen 4: Margin Policy

- Set target margin
- Activate/deactivate policies

### Screen 5: Pricing Model Preview + Publish

- Create draft pricing model for a given `effective_from`, currency, and month snapshot
- Show computed plan prices
- Show Stripe Price IDs that will be created
- Publish action

Publishing requires:

- explicit confirmation
- optional reason field
- recorded audit trail

## 🔐 Authorization / Guards

Follow the impersonation approach:

- `before_action :authenticate_user!`
- `before_action :require_admin_super_admin!`

`require_admin_super_admin!` logic:

- deny unless `current_user&.admin? && current_user&.super_admin?`

## 🧵 Background Jobs

### 1) Heroku inventory snapshot job

- Daily: capture space inventory and persist `heroku_app_inventory_snapshots`

### 2) Vendor usage ingestion jobs

- DeepL:
  - daily poll `usage` and store delta in `external_service_daily_usages`
- OpenAI:
  - instrument internal calls (no external polling)
- Google Vision:
  - instrument internal calls
- Stripe fees:
  - daily ingest balance transactions (v2) OR manual monthly entry (v1)

### 3) Monthly rollup job

- At month end or on-demand:
  - compute monthly totals
  - populate `external_service_monthly_costs` (if source is derived) or just provide a preview

## 💳 Stripe Price Publication (per model version)

When a pricing model is published:

- create Stripe Prices per:
  - plan
  - interval (month/year)
  - currency (USD/EUR)
  - version

Persist `stripe_price_id` on `pricing_model_plan_prices`.

## 🧪 Test Plan

### Unit tests

- `require_admin_super_admin!` guard
- pricing compilation determinism
- margin calculations

### Request/system tests

- Admin screens inaccessible for non-super-admin
- Publish flow requires confirmation
- Published pricing model immutable

## ✅ Acceptance Criteria

- [ ] Admin+super_admin can view monthly cost insights (infra + vendor + staff/support)
- [ ] Admin+super_admin can enter staff/support costs per month
- [ ] Admin+super_admin can configure target margin
- [ ] Admin+super_admin can preview computed plan prices (USD/EUR)
- [ ] Admin+super_admin can publish a pricing model version
- [ ] Publishing creates Stripe Prices per plan/currency/interval/version
- [ ] New signups use the latest published pricing model

## ✅ Implementation Checklist

- [ ] Implement `Admin::` routes/controllers/views for:
  - [ ] cost insights dashboard
  - [ ] vendor monthly costs management
  - [ ] staff/support monthly cost entry
  - [ ] margin policy management
  - [ ] pricing model preview + publish
- [ ] Implement access guard `require_admin_super_admin!` patterned after admin impersonation, enforcing `admin && super_admin`
- [ ] Add schema + migrations for:
  - [ ] `external_service_daily_usages`
  - [ ] `external_service_monthly_costs`
  - [ ] `staff_cost_snapshots`
  - [ ] `profit_margin_policies`
- [ ] Implement usage ingestion/metering:
  - [ ] DeepL daily usage poll and delta storage
  - [ ] OpenAI usage metering via internal instrumentation
  - [ ] Google Vision usage metering via internal instrumentation
  - [ ] Stripe fees ingestion (or v1 manual monthly entry)
- [ ] Integrate Heroku cloud cost inputs by referencing outputs from `heroku-cost-inventory-spaces-pipelines.md`
- [ ] Implement monthly rollups and preview computation for total cost by currency
- [ ] Implement pricing model compilation + Stripe price publication hooks (delegating to the dynamic pricing spec)
- [ ] Add audit trail for publish actions (who, when, optional reason)
- [ ] Write extensive unit tests for:
  - [ ] cost aggregation and rollups
  - [ ] margin policy math
  - [ ] publish immutability rules
  - [ ] admin/super_admin access guard
- [ ] Write extensive system tests for:
  - [ ] full admin workflow: enter costs → set margin → preview → publish
  - [ ] authorization: non super-admin cannot access any cost/publish pages
  - [ ] publish creates Stripe prices and persists IDs (mocked)

## 🧾 Definition of Done

- [ ] All checklist items completed
- [ ] Extensive unit tests and system tests implemented and **all passing**
- [ ] All admin cost/publish screens are `Admin::` only (no Madmin usage)
- [ ] All cost data is inaccessible to non `admin && super_admin`
- [ ] Publishing flow is auditable and pricing models are immutable after publish
- [ ] Documentation updated and cross-references accurate

---

**Created**: February 9, 2026

**Status**: Draft
