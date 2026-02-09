# Heroku Cost Inventory (Spaces + Pipelines) — Technical Specification

## � Related Specifications

- `cost-insights-and-pricing-model-publisher-admin-system.md`
- `real-dynamic-pricing-plans-cost-indexed.md`

## �📋 Feature Overview

**Feature Name**: Heroku Cost Inventory (Spaces + Pipelines)

**Priority**: High (dependency for cost-indexed pricing)

**Category**: Finance Ops / Infrastructure / Billing Inputs

**Estimated Effort**: Medium (3-6 days for v1 inventory + snapshot storage; longer if invoice ingestion is required)

**Target Release**: 2026

## 🎯 Goal

Provide a reliable, automated way to:

- Inventory all Heroku apps required to operate mellow.menu across environments
- Classify each app as `production` / `staging` / `development` / `ephemeral`
- Extract key cost-driving metadata (formation, dyno sizes, add-on plans)
- Persist monthly cost snapshots that feed the **PricingModel** cost inputs

This document covers the **cloud/Heroku** portion of the broader initiative to:

- produce detailed running-cost insights across cloud + third-party SaaS
- allow super admins to input support/staff costs + target margin
- compute plan prices
- review and publish a new pricing model version

## ✅ Decisions (Confirmed)

- Environment grouping/discovery uses **Heroku Spaces**.
- `smart-menu` is the primary space.
- **Heroku Pipelines are in use** and should be the primary env classifier.
- Any UI/UX for cost management must be visible only to users who are:
  - `admin: true` AND
  - `super_admin: true`

## 📐 Scope

### In scope (v1)

- Heroku Platform API integration (read-only)
- Inventory: Space → apps → pipeline stage → environment
- Extraction: formation + add-ons (Postgres/Redis/etc.)
- Persisting inventory snapshots (daily) and a monthly “cost snapshot” row per environment
- Admin UI: view inventory, set cost coefficients, and confirm monthly rollups

### Out of scope (v1)

- Pulling actual invoice totals from Heroku billing exports
- Multi-space aggregation (unless explicitly required)
- Non-Heroku infra providers

## 🔌 Integration: Heroku Platform API

### Recommended Ruby Gem

- `platform-api` (official-ish Heroku Platform API Ruby client)

Rationale:

- Works well in Rails as a service client
- Provides authenticated access to:
  - spaces
  - apps
  - formations
  - add-ons
  - pipelines + stages

### Credentials

- Add `HEROKU_PLATFORM_API_TOKEN` as a production/staging config var.
- Token must have permissions to read spaces, apps, formations, add-ons, and pipelines.
- Do not expose token in logs.

### Proposed service objects

- `Heroku::PlatformClient`
  - wraps `PlatformAPI.connect_oauth(ENV.fetch('HEROKU_PLATFORM_API_TOKEN'))`

- `Heroku::SpaceInventoryService`
  - `fetch(space_name: "smart-menu")` → returns normalized inventory list

- `Heroku::EnvironmentClassifier`
  - `classify(app:, pipeline_stage:)` → `production|staging|development|ephemeral|unknown`

## 🧠 Environment Classification Rules

### Primary rule (preferred)

- Determine the app’s pipeline + stage (e.g. `production`, `staging`, `development`, `review`).
- Map pipeline stage → environment:
  - `production` → `production`
  - `staging` → `staging`
  - `development` → `development`
  - `review` (or similar) → `ephemeral`

### Fallback rule

If pipeline metadata cannot be fetched:

- infer from app name patterns:
  - contains `-staging` → `staging`
  - contains `-dev` → `development`
  - contains `-pr-`, `review-`, `-review-` → `ephemeral`
  - else → `unknown` (must be flagged in UI)

## 📦 What to Extract Per App

### Formation (dyno types + sizes)

For each process type (e.g. `web`, `worker`):

- quantity
- size (e.g. `standard-1x`, `performance-m`, etc.)

### Add-ons

For each add-on:

- add-on name
- service name (e.g. `heroku-postgresql`, `heroku-redis`)
- plan name (e.g. `standard-0`, `mini`, etc.)

### Space

- space name (should be `smart-menu`)

### Pipeline metadata

- pipeline id/name
- stage name

## 🗄️ Data Model

This subsystem needs two levels:

1) raw inventory snapshots (auditable)
2) curated monthly cost snapshot (used by pricing)

### Table: `heroku_app_inventory_snapshots`

- `captured_at` datetime
- `space_name` string
- `app_id` string
- `app_name` string
- `pipeline_id` string nullable
- `pipeline_stage` string nullable
- `environment` string (`production|staging|development|ephemeral|unknown`)
- `formation_json` jsonb
- `addons_json` jsonb
- `notes` text nullable

Indexes:

- `index` on `[space_name, captured_at]`
- `index` on `[app_name, captured_at]`

### Table: `infra_cost_snapshots`

One row per month per environment.

- `month` date (normalized to first day of month)
- `provider` string (v1: `heroku`)
- `space_name` string (`smart-menu`)
- `environment` string (`production|staging|development|ephemeral`)

Fields used by pricing engine:

- `estimated_monthly_cost_cents` integer
- `currency` string (optional; if you want to store costs in a base currency; otherwise treat as internal base currency)

Optional evidence fields:

- `app_count` integer
- `formation_rollup_json` jsonb
- `addons_rollup_json` jsonb

Ephemeral modeling inputs (only if env = `ephemeral`):

- `assumed_concurrent_instances` integer
- `avg_lifetime_days` integer
- `per_instance_monthly_cost_cents` integer

Audit:

- `created_by_user_id` bigint
- `updated_by_user_id` bigint

## 🧮 Cost Calculation (v1)

Heroku Platform API does not reliably provide invoice totals in a clean way.

So v1 uses a hybrid approach:

- **Inventory is automatic** (what exists, sizes, plans)
- **Cost coefficients are maintained internally** (mapping plan/size → cost)

### Internal coefficient tables (recommended)

- `heroku_dyno_size_costs`
  - `dyno_size` (e.g. `standard-1x`)
  - `cost_cents_per_month`

- `heroku_addon_plan_costs`
  - `addon_service` (e.g. `heroku-postgresql`)
  - `plan_name`
  - `cost_cents_per_month`

Rollup algorithm:

- For each app in space:
  - sum(formation quantity × dyno_size_cost)
  - + sum(addon_plan_cost)
- Group totals by `environment`
- Persist result into `infra_cost_snapshots` for the month

### Ephemeral environments

Ephemeral apps may be short-lived. Two options:

- **Option A (simplest)**: treat ephemeral as a monthly average using modeling fields:
  - `assumed_concurrent_instances`
  - `avg_lifetime_days`
  - `per_instance_monthly_cost_cents`

- **Option B (more accurate)**: compute from inventory snapshots by integrating “active days” per app.

v1 should start with Option A.

## 🧑‍💻 Admin UI / UX

All screens must be gated to users who are `admin && super_admin`.

Do **not** implement these screens inside `Madmin` (there is a plan to migrate away from it). Implement using a dedicated `Admin::` namespace, following the approach used by the super-admin impersonation feature (`Admin::ImpersonationsController` + `app/views/admin/...`).

### Screen 1: Space Inventory

- Select space (default `smart-menu`)
- Show table:
  - app name
  - env classification (pipeline stage)
  - web dynos / worker dynos
  - postgres plan
  - redis plan
  - other add-ons
  - last captured time

### Screen 2: Cost Coefficients

- Dyno size cost mapping
- Add-on plan cost mapping
- “Last updated by” and audit

### Screen 3: Monthly Infra Cost Snapshot

- month selector
- per-environment totals
- breakdown previews
- approve/lock snapshot (optional)

## 🔐 Security / Access Control

- Controller guard: require `current_user.admin? && current_user.super_admin?`
- Avoid exposing raw API responses publicly.
- Store only required fields from Heroku in DB.

Recommended implementation:

- Add `before_action :authenticate_user!`
- Add a small guard method similar to `require_super_admin!` from the impersonation feature, but enforce **both** `admin?` and `super_admin?`.

## 🧪 Test Plan

### Unit tests

- environment classification mapping (pipeline stage → env)
- coefficient rollup logic

### Integration tests

- inventory fetch service (mock PlatformAPI)
- snapshot creation

## ✅ Acceptance Criteria

- [ ] System can list all apps in the `smart-menu` space
- [ ] System can classify apps by pipeline stage into env buckets
- [ ] System can extract formation + add-on plan data
- [ ] System can produce a monthly infra cost snapshot per environment
- [ ] Admin UI is only accessible to `admin && super_admin`
- [ ] PricingModel inputs can reference the monthly infra totals

## ✅ Implementation Checklist

- [ ] Add `platform-api` gem and configure `HEROKU_PLATFORM_API_TOKEN` for environments where ingestion runs
- [ ] Implement `Heroku::PlatformClient` wrapper with safe logging and timeouts
- [ ] Implement `Heroku::SpaceInventoryService.fetch(space_name: 'smart-menu')`
- [ ] Implement pipeline stage → environment classifier (production/staging/development/review→ephemeral)
- [ ] Add DB tables:
  - [ ] `heroku_app_inventory_snapshots`
  - [ ] `infra_cost_snapshots`
- [ ] Add cost coefficient tables (dyno sizes + add-on plans) or embed coefficients in an internal config store
- [ ] Implement rollup computation to generate per-environment monthly infra totals
- [ ] Implement Admin namespace screens (not Madmin): inventory viewer + coefficient editor + monthly snapshot viewer
- [ ] Add background jobs:
  - [ ] daily inventory snapshot capture
  - [ ] monthly rollup (and on-demand recompute)
- [ ] Write extensive unit tests for:
  - [ ] pipeline stage classification
  - [ ] rollup math and coefficient mapping
  - [ ] idempotent snapshot creation
- [ ] Write extensive system tests for:
  - [ ] admin/super_admin access gating
  - [ ] inventory visibility + month rollup visibility

## 🧾 Definition of Done

- [ ] All checklist items completed
- [ ] Extensive unit tests and system tests implemented and **all passing**
- [ ] Inventory and rollups work across `production`, `staging`, `development`, and `ephemeral`
- [ ] Admin-only pages are implemented under `Admin::` and inaccessible to non `admin && super_admin`
- [ ] Documentation updated and cross-references accurate

---

**Created**: February 9, 2026

**Status**: Draft
