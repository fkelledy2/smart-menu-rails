# Dynamic Pricing Plans (Cost-Indexed) — User Guide

**Feature #14 | Completed 2026-04-05**

---

## Overview

Dynamic Pricing Plans ensures that new restaurant signups are charged prices derived from mellow.menu's current running costs plus a target gross margin. Existing customers are never automatically repriced — their price is locked at the point of signup for the life of their subscription.

---

## How It Works

### 1. Feature Flag

Cost-indexed pricing is gated behind the `cost_indexed_pricing` Flipper flag. Until you enable this flag, the platform continues to use the static Stripe Price IDs stored on each Plan record. Enabling the flag activates dynamic price resolution for all new signups and plan changes.

To enable:
1. Go to `/flipper` (admin-only)
2. Find `cost_indexed_pricing`
3. Enable it globally or for a specific percentage of actors

### 2. Create a Pricing Model

1. Navigate to **Admin > Pricing Models** (`/admin/pricing_models`)
2. Click **New Pricing Model**
3. Enter:
   - **Version** — a unique label, e.g. `2026_Q2`
   - **Currency** — `EUR` or `USD`
   - **Total Cost (cents)** — your total monthly running cost in cents (e.g. `500000` = €5,000/month)
   - **Target Gross Margin %** — e.g. `60` for 60% gross margin
4. Save as draft

### 3. Preview Computed Prices

Before publishing, verify the computed plan prices:
1. Open the draft pricing model
2. Click **Preview Prices**
3. Review the monthly and annual prices for each active plan

The algorithm:
- `required_revenue = total_cost / (1 - target_margin / 100)`
- `per_weight_unit = required_revenue / sum_of_plan_weight_multipliers`
- `plan_monthly_price = per_weight_unit * plan.weight_multiplier`
- `plan_annual_price = monthly * 10` (2 months free)

### 4. Publish the Pricing Model

Publishing is **irreversible** — corrections require a new version.

1. Open the draft pricing model
2. Optionally enter a **Publish Reason** for audit trail purposes
3. Click **Publish and Create Stripe Prices**

On publish:
- Stripe Price objects are created for every plan / interval / currency combination
- The model status changes to `published`
- The model is locked — no further edits are possible

If Stripe Price creation fails for any item, the entire publish rolls back and no model is marked published.

### 5. How New Signups Are Priced

When `cost_indexed_pricing` is enabled and a published model exists:
1. The checkout flow resolves the restaurant's billing currency from its country (`EUR` default)
2. The current published model's `stripe_price_id` is used as the Stripe checkout line item
3. After checkout completes, the `Userplan` record is updated with:
   - `pricing_model_id` — the model used
   - `applied_price_cents` — the price paid
   - `applied_currency` — EUR or USD
   - `applied_interval` — `month` or `year`
   - `applied_stripe_price_id` — the Stripe Price ID

### 6. What Customers See

On the **Billing page** (`/userplans/:id/edit`):

If a pricing snapshot is recorded, the customer sees:

> Your pricing version: 2026_Q2 — Price locked since signup — EUR 49.00/month

This message appears for all customers with a `pricing_model_id` set on their Userplan.

---

## Admin Override: Keep Original Cohort Pricing

When a customer wants to change plan but should retain their original cohort pricing (e.g. a grandfathered customer), a super_admin can apply an override:

1. Navigate to **Admin > Pricing Models** and open the relevant pricing model
2. Find the customer in the **Customers on this Pricing Version** table
3. Click **Change Plan** for that customer
4. Select the new plan and enter a **reason** (required for audit)
5. Click **Apply Override**

This sets:
- `pricing_override_keep_original_cohort = true`
- `pricing_override_by_user_id` — the admin who approved
- `pricing_override_at` — timestamp of the override
- `pricing_override_reason` — the stated reason

The customer's billing page will show a **Cohort Override** badge.

---

## Plan Change (Self-Serve)

When a customer changes plan via the self-serve billing portal:
1. If `cost_indexed_pricing` is enabled, the new plan's price is resolved from the current published pricing model
2. The `Userplan` is updated with the new pricing snapshot (new model, new price)
3. If no pricing model exists, the plan is changed using the plan's static Stripe price

---

## Backfilling Existing Customers

To preserve audit completeness when activating cost-indexed pricing:

```ruby
result = Pricing::LegacyBackfillService.run
# => Updates all Userplan records with nil pricing_model_id to the legacy_v0 sentinel
```

The `legacy_v0` sentinel is a published pricing model with `effective_from` set to epoch (1970-01-01), making it sort below all real models. It is created automatically by the backfill service if it doesn't exist.

---

## Managing Pricing Model Versions

- Only **one** pricing model is "current" at a time — the published model with the most recent `effective_from`
- To introduce a new pricing cycle: create a new draft, preview, then publish
- Old published models are retired automatically when a newer one is published (they remain visible for audit)
- Published models are **immutable** — corrections require a new version

---

## Key Files

| File | Purpose |
|------|---------|
| `app/models/pricing_model.rb` | PricingModel model, `current` class method |
| `app/models/pricing_model_plan_price.rb` | Per-plan prices per model |
| `app/models/userplan.rb` | Pricing snapshot fields |
| `app/services/pricing/model_compiler.rb` | Computes plan prices from cost inputs |
| `app/services/pricing/model_resolver.rb` | Resolves current model + prices |
| `app/services/pricing/model_publisher.rb` | Orchestrates the full publish workflow |
| `app/services/pricing/stripe_price_publisher.rb` | Creates Stripe Price objects |
| `app/services/pricing/pricing_recorder.rb` | Records pricing snapshot on Userplan |
| `app/services/pricing/legacy_backfill_service.rb` | Backfills pre-pricing customers |
| `app/controllers/admin/pricing_models_controller.rb` | Admin CRUD + publish |
| `app/controllers/admin/userplans_controller.rb` | Admin pricing override endpoint |
| `app/controllers/payments/subscriptions_controller.rb` | Signup checkout (flag-gated) |
| `app/controllers/userplans_controller.rb` | Plan change + stripe_success recording |
| `app/policies/pricing_model_policy.rb` | super_admin only access |
| `app/policies/userplan_policy.rb` | pricing_override? super_admin gate |

---

## Flipper Flag Summary

| Flag | Effect |
|------|--------|
| `cost_indexed_pricing` | Enables dynamic price resolution in checkout and plan change flows. Off by default. Enable after first pricing model is published. |
