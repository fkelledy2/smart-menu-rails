# Cost Insights + Pricing Model Publisher — User Guide

**Feature**: #15 Cost Insights and Pricing Model Publisher Admin System
**Status**: Completed 2026-03-31
**Flipper flags**: `cost_insights_admin`, `cost_indexed_pricing`

---

## What This Feature Does

This feature gives Smart Menu super-admins a single admin dashboard to:

1. Track all operating costs (infrastructure, vendor APIs, staff/support)
2. Set a target gross margin policy
3. Compile and publish a new pricing model — converting total costs into per-plan monthly/annual prices via a margin engine
4. Manage the full lifecycle of pricing models (draft → published → retired)

---

## How to Access

All screens are under the `Admin` namespace and require `super_admin` access.

| URL | Screen |
|-----|--------|
| `/admin/cost_insights` | Overview dashboard with total cost and latest pricing model |
| `/admin/vendor_costs` | Manage external vendor API costs (OpenAI, DeepL, etc.) |
| `/admin/staff_costs` | Manage staff and support cost snapshots |
| `/admin/margin_policies` | Manage gross margin policies |
| `/admin/pricing_models` | Manage pricing models |
| `/admin/heroku_inventories` | Heroku infra inventory (see #16 guide) |

---

## Cost Tracking

### Vendor Costs

External API costs (OpenAI, DeepL, Google Vision, Stripe) are tracked via `ExternalServiceMonthlyCost`. Navigate to **Admin → Vendor Costs** to:

- Add a new monthly cost entry for a service
- Set the amount in cents, currency, and source (`manual`, `api_ingest`, or `csv_import`)
- Add notes or evidence links (e.g., invoice URLs)

Automated ingestion:
- **DeepL**: `DeeplUsageIngestionJob` polls the DeepL usage API daily
- **OpenAI**: `OpenaiUsageRollupJob` rolls up Redis counters daily (counters are incremented by `VendorUsage::OpenaiMeteringService.record(...)` throughout the app)

### Staff Costs

Navigate to **Admin → Staff Costs** to record monthly staff/support/ops expenses as `StaffCostSnapshot` records. Each snapshot captures:

- `support_cost_cents` — customer-facing support team
- `staff_cost_cents` — engineering and operations
- `other_ops_cost_cents` — miscellaneous ops

### Infrastructure Costs

Infra costs flow from the Heroku Cost Inventory (#16). The `Cost Insights` dashboard aggregates:

- **Production-only** infra cost from `InfraCostSnapshot` (production environment only — staging/dev are excluded from pricing calculations)
- All vendor monthly costs for the selected month
- All staff monthly costs for the selected month

---

## Gross Margin Policies

Navigate to **Admin → Margin Policies** to define target and floor margin percentages.

Only **one policy can be active at a time**. To switch:

1. Create a new policy (it starts as `inactive`)
2. Click **Activate** on the new policy — this automatically deactivates the previously active one

The `floor_gross_margin_pct` must be below the `target_gross_margin_pct`. The margin engine uses `target_gross_margin_pct` for price calculation.

---

## Pricing Models

### Lifecycle

```
draft → published → retired
```

- **Draft**: fully editable; prices can be recalculated
- **Published**: immutable; prices are locked; the model is live for new subscriptions
- **Retired**: archived; no longer used for new subscriptions

Only one model should be published at a time. When you publish a new model, retire the old one manually.

### Creating a Pricing Model

1. Navigate to **Admin → Pricing Models → New**
2. Enter a `version` slug (e.g., `v2-apr-2026`)
3. Enter `Total cost (cents)` — this can be left blank to auto-populate from the Cost Insights calculator
4. Enter `Target gross margin %` — or leave blank to use the current active margin policy
5. Save as **Draft**

### Previewing Prices

From the pricing model show page, click **Preview**. This runs the margin engine and shows you the computed monthly and annual price for each plan, without saving anything. The preview uses the model's stored `inputs_total_cost_cents` and `inputs_target_gross_margin_pct`.

### Publishing

From the pricing model show page, click **Publish**. This:

1. Compiles `PricingModelPlanPrice` records for each plan × interval × currency combination
2. Creates matching `Stripe::Price` objects via `Pricing::StripePricePublisher`
3. Locks the model as `published` (immutable)

If Stripe price creation fails, the entire publish is rolled back and the model remains in `draft`.

**Note**: Publishing requires the `cost_indexed_pricing` Flipper flag to be enabled for Stripe prices to be active. In development/test, Stripe API calls are stubbed.

---

## The Margin Engine

The margin engine (`CostInsights::MarginEngine`) converts total operating cost into per-plan prices:

```
required_revenue = total_cost / (1 - target_margin_pct / 100)
weight_sum       = sum of all active plans' weight_multiplier values
per_weight_unit  = required_revenue / weight_sum  (rounded up)

plan_monthly_price = per_weight_unit × plan.weight_multiplier  (rounded up)
plan_annual_price  = plan_monthly_price × 10  (10 months = 2 months free)
```

Default weight multipliers (set on the `Plan` model):

| Plan | Weight Multiplier |
|------|------------------|
| Starter | 1.0 |
| Pro | 2.0 |
| Business | 4.0 |
| Enterprise | 8.0 |

Weight multipliers can be adjusted directly on the `Plan` record via the Rails console:

```ruby
Plan.find_by(name: 'Pro').update!(weight_multiplier: 2.5)
```

---

## Triggering a Monthly Rollup

From **Admin → Cost Insights**, click **Trigger Monthly Rollup**. This enqueues `MonthlyCostRollupJob` for the current month, which logs total usage per service. Vendor monthly costs are expected to be entered manually (or ingested via the daily jobs) before running the rollup.

---

## Architecture Notes

- `CostInsights::TotalCalculator` — aggregates infra + vendor + staff costs for a given month
- `CostInsights::MarginEngine` — deterministic price calculator; same inputs always produce same outputs
- `Pricing::ModelCompiler` — creates `PricingModelPlanPrice` records in a transaction
- `Pricing::StripePricePublisher` — creates Stripe prices; rolls back on failure
- `Pricing::ModelPublisher` — orchestrates compile + Stripe publish + status lock
- `Pricing::ModelResolver` — resolves the current published pricing model for a given restaurant
- `VendorUsage::OpenaiMeteringService` — Redis counter for OpenAI usage; rolled up daily
- `VendorUsage::DeeplIngestionService` — polls DeepL usage API
