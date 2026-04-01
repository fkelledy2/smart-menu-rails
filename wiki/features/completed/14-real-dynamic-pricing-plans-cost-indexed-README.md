# Dynamic Pricing Plans (Cost-Indexed) — User Guide

**Feature**: #14 Real Dynamic Pricing Plans — Cost-Indexed
**Status**: Completed 2026-03-31
**Flipper flag**: `cost_indexed_pricing`

---

## What This Feature Does

This feature replaces hard-coded plan prices with a cost-indexed pricing system. Plan prices are now calculated from actual operating costs using a margin engine and published as immutable `PricingModel` records linked to real Stripe `Price` objects.

Key capabilities:

- Every restaurant subscription is associated with a `PricingModel` version, so you always know which price cohort they are on
- Existing customers are backfilled to a `legacy_v0` sentinel model (price-locked; no Stripe price IDs required)
- New customers automatically receive prices from the current published model
- Individual subscriptions can be overridden (e.g., for legacy discounts or early-adopter pricing)
- Annual pricing is always monthly × 10 (2 months free)

---

## How Pricing Works End-to-End

```
Operating Costs (infra + vendor + staff)
        ↓
Margin Engine (target gross margin %)
        ↓
PricingModel (draft)
        ↓  [publish]
PricingModelPlanPrice records + Stripe Prices
        ↓
New subscriptions → Userplan.pricing_model_id → PricingModelPlanPrice
```

For the full cost → price flow, see the Cost Insights guide (`15-cost-insights-and-pricing-model-publisher-README.md`).

---

## Plan Weight Multipliers

Each plan has a `weight_multiplier` column that controls how much of the per-unit revenue it should receive relative to the cheapest plan.

Default values:

| Plan | weight_multiplier | Monthly price relative to Starter |
|------|------------------|-----------------------------------|
| Starter | 1.0 | 1× |
| Pro | 2.0 | 2× |
| Business | 4.0 | 4× |
| Enterprise | 8.0 | 8× |

To adjust a multiplier (triggers on the next pricing model compile):

```ruby
Plan.find_by(name: 'Business').update!(weight_multiplier: 5.0)
```

---

## Annual Pricing

Annual price = monthly price × 10. This is equivalent to 2 months free (a ~17% discount). The constant is defined as `ANNUAL_FACTOR = 10` in `CostInsights::MarginEngine`.

---

## Existing Customers — Legacy Backfill

All `Userplan` records that exist before cost-indexed pricing was introduced are associated with the `legacy_v0` sentinel pricing model. This model:

- Is published but has no Stripe price IDs
- Uses `effective_from = Time.at(0)` (epoch) — it sorts before all real models
- Is immutable and cannot be deleted

To backfill manually (e.g., after a data migration):

```ruby
Pricing::LegacyBackfillService.backfill!
```

This is idempotent — running it twice produces the same result.

---

## Pricing Overrides

A super admin can lock a specific subscription to its current pricing regardless of future model publishes:

```ruby
userplan = Userplan.find(...)
userplan.update!(
  pricing_override_keep_original_cohort: true,
  pricing_override_by_user_id: admin_user.id,
  pricing_override_at: Time.current,
  pricing_override_reason: 'Early adopter discount — grandfathered until 2027',
)
```

Check override status:

```ruby
userplan.overridden_pricing?      # => true
userplan.pricing_version          # => "legacy_v0" or "v1-jan-2026"
userplan.price_locked?            # => true if pricing_model_id is set
```

---

## Resolving the Current Price for a Restaurant

```ruby
# Get the current published pricing model
model = PricingModel.current

# Get the price for a specific plan + interval + currency
price = model.price_for(plan: plan, interval: :month, currency: 'EUR')
# => PricingModelPlanPrice instance

price.price_cents   # => 4900
price.price_euros   # => 49.0
price.stripe_price_id  # => "price_1ABC..."
```

---

## OpenAI Usage Metering

OpenAI API calls throughout the app automatically record usage to Redis counters via `VendorUsage::OpenaiMeteringService`:

```ruby
VendorUsage::OpenaiMeteringService.record(
  dimension: 'chat_completions',
  units: response.usage.total_tokens,
  restaurant_id: restaurant.id,  # optional
)
```

Supported dimensions: `chat_completions`, `image_generation`, `embeddings`, `audio_transcription`.

Redis counters are rolled up to `ExternalServiceDailyUsage` records daily by `OpenaiUsageRollupJob`. These records feed the Cost Insights dashboard.

---

## Enabling Stripe Price Creation

By default, Stripe price creation is **stubbed** in development and test (the publisher returns a mock price ID).

To enable live Stripe price creation:

1. Ensure `STRIPE_SECRET_KEY` is set
2. Enable the Flipper flag:
   ```ruby
   Flipper.enable(:cost_indexed_pricing)
   ```

---

## Publishing a New Pricing Model — Quick Reference

1. Enter costs in **Admin → Vendor Costs** and **Admin → Staff Costs** for the month
2. Trigger the Heroku cost rollup from **Admin → Heroku Inventories**
3. Create a new **Pricing Model** with the total cost and target margin
4. Click **Preview** to validate the computed prices
5. Click **Publish** — this compiles Stripe prices and locks the model
6. Update Stripe products/subscriptions to use the new Price IDs as needed
7. Retire the previous published model from **Admin → Pricing Models**

---

## Architecture Notes

- `app/models/pricing_model.rb` — `LEGACY_VERSION = 'legacy_v0'`; `immutable?` enforced after publish
- `app/models/pricing_model_plan_price.rb` — per-plan × interval × currency record with Stripe price ID
- `app/models/plan.rb` — `weight_multiplier` decimal column; `has_many :pricing_model_plan_prices`
- `app/models/userplan.rb` — `belongs_to :pricing_model, optional: true`; override columns
- `app/services/pricing/legacy_backfill_service.rb` — idempotent backfill to `legacy_v0`
- `app/services/pricing/model_resolver.rb` — resolves current model for a restaurant
- `app/services/pricing/stripe_price_publisher.rb` — creates Stripe prices; rolls back on failure
- `app/policies/pricing_model_policy.rb` — draft-only edit/destroy; super_admin gate
- Migrations: `20260331215516_create_pricing_models.rb`, `20260331215521_create_pricing_model_plan_prices.rb`, `20260331215525_add_pricing_fields_to_userplans.rb`, `20260331215530_add_weight_multiplier_to_plans.rb`
