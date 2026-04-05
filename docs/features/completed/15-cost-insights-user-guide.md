# Cost Insights + Pricing Model Publisher — User Guide

## Overview

The Cost Insights system gives super admins a unified view of mellow.menu's running costs (Heroku infrastructure, vendor APIs, and staff) and the ability to publish versioned pricing models that drive subscription prices.

All screens are accessible only to users with **admin: true + super_admin: true** (i.e. `admin@mellow.menu` credentials).

---

## Navigating to Cost Insights

From the admin navigation, go to **Cost Insights** (or visit `/admin/cost_insights`).

The dashboard is gated behind the Flipper flag `cost_insights_admin`. Enable it before using:

```ruby
# Rails console
Flipper.enable(:cost_insights_admin)
```

---

## Screen 1 — Cost Insights Dashboard

**URL:** `/admin/cost_insights`

Shows a monthly summary of all platform costs:

| Card | Source |
|------|--------|
| Heroku (Production) | `InfraCostSnapshot` records for `environment = production` |
| Vendor APIs | `ExternalServiceMonthlyCost` records |
| Staff + Support | `StaffCostSnapshot` record for the month |
| Total | Sum of all three |

**Filters:** Use the month date picker and currency selector (EUR/USD) at the top to change the view period.

**Active Margin Policy:** Displays the currently active `ProfitMarginPolicy` (target and floor gross margin %).

**Trigger Monthly Rollup:** A form at the bottom lets you manually trigger `MonthlyCostRollupJob` for any month. This aggregates daily vendor usage records into monthly totals.

---

## Screen 2 — Vendor Costs

**URL:** `/admin/vendor_costs`

Manage monthly vendor API cost entries (OpenAI, DeepL, Google Vision, Stripe, Heroku, Other).

### Creating a vendor cost entry
1. Click **New Vendor Cost**
2. Select the month, service, currency, and amount in cents (e.g. 8000 = €80.00)
3. Choose source: `manual` (default for v1), `api_ingest`, or `csv_import`
4. Optionally add notes
5. Click **Save**

### Automatic ingestion
DeepL usage is automatically ingested daily via `DeeplUsageIngestionJob`. OpenAI usage is tracked via `VendorUsage::OpenaiMeteringService` (Redis counters rolled up daily by `OpenaiUsageRollupJob`).

---

## Screen 3 — Staff / Support Costs

**URL:** `/admin/staff_costs`

Enter monthly staff and support cost snapshots.

| Field | Description |
|-------|-------------|
| Month | First day of the billing month |
| Currency | EUR or USD |
| Support cost (cents) | Customer support staff costs |
| Staff cost (cents) | Engineering / product staff costs |
| Other ops cost (cents) | Other operational costs |
| Notes | Free-text notes |

Each month/currency combination can have one snapshot. The total feeds directly into the Cost Insights dashboard.

---

## Screen 4 — Margin Policies

**URL:** `/admin/margin_policies`

Configure the target and floor gross margin percentages used to compute plan prices.

| Field | Description |
|-------|-------------|
| Key | Unique identifier (e.g. `default`) |
| Target gross margin % | Desired profit margin (e.g. 60 means 60%) |
| Floor gross margin % | Minimum acceptable margin (must be below target) |
| Status | `active` or `inactive` |

Only one policy needs to be active at a time. Use the **Activate / Deactivate** buttons to switch.

---

## Screen 5 — Pricing Models

**URL:** `/admin/pricing_models`

Manage versioned pricing models. Each model takes cost inputs and computes plan prices via `Pricing::ModelCompiler` + `CostInsights::MarginEngine`.

### Workflow

#### 1. Create a Draft
Click **New Pricing Model** and provide:
- **Version** — unique string (e.g. `2026_Q2`)
- **Currency** — EUR or USD
- **Total Cost (cents)** — total monthly running cost in cents
- **Target Gross Margin %** — the margin target to price against

#### 2. Preview
Click **Preview** on a draft model to see computed plan prices before publishing. The preview shows:
- Required revenue to hit the margin target
- Per-weight-unit revenue
- Computed monthly and annual prices for each active plan

No records are saved during preview.

#### 3. Publish
Click **Publish** on a draft model. Optionally enter a publish reason.

Publishing:
1. Runs `Pricing::ModelCompiler` to compute and save `PricingModelPlanPrice` records
2. Creates Stripe Price objects via `Pricing::StripePricePublisher`
3. Sets the model status to `published` and records `published_at`, `published_by`

**Published models are immutable** — they cannot be edited or deleted.

#### 4. Draft Cleanup
Delete draft models at any time from the index or show page.

---

## Heroku Cost Inventory

**URL:** `/admin/heroku_inventories`

Automatically tracked Heroku infrastructure costs for the `smart-menu` space.

### How it works
1. `HerokuInventorySnapshotJob` runs daily and calls `Heroku::SpaceInventoryService.fetch(space_name: 'smart-menu')` to capture all apps with their formation and add-on details.
2. `HerokuMonthlyCostRollupJob` computes monthly cost totals using the coefficient tables (`HerokuDynoSizeCost`, `HerokuAddonPlanCost`).
3. Results are stored in `InfraCostSnapshot` and shown on the Cost Insights dashboard.

### Coefficient tables
Initial dyno and add-on cost coefficients must be populated before the first rollup. Edit them at `/admin/heroku_inventories/coefficients`.

### Environment classification
Apps are classified by pipeline stage: `production`, `staging`, `development`, `ephemeral`, or `unknown`.

### Triggering manually
From the admin UI, you can trigger both snapshot and rollup jobs on-demand.

---

## Feature Flag

All screens respect the `cost_insights_admin` Flipper flag. Enable it before use:

```ruby
Flipper.enable(:cost_insights_admin)
# Or enable for a specific user:
Flipper.enable(:cost_insights_admin, User.find_by(email: 'admin@mellow.menu'))
```

---

## Background Jobs

| Job | Schedule | Purpose |
|-----|----------|---------|
| `DeeplUsageIngestionJob` | Daily | Polls DeepL usage API |
| `OpenaiUsageRollupJob` | Daily | Rolls up Redis OpenAI usage counters |
| `MonthlyCostRollupJob` | On-demand or month-end | Aggregates daily usage into monthly totals |
| `HerokuInventorySnapshotJob` | Daily | Captures Heroku app inventory |
| `HerokuMonthlyCostRollupJob` | On-demand or month-end | Computes infra cost from snapshots |

---

## Security Notes

- All screens require `admin? && super_admin?` — plain admin accounts are redirected to root.
- Cost data is never exposed to non-super-admins via Pundit policies.
- `HEROKU_PLATFORM_API_TOKEN` is read-only and must never appear in logs.
- Published pricing models are immutable (enforced at model and controller level).
