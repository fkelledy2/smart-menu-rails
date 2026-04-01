---
name: Cost-Indexed Pricing System v1
description: Features #14/#15/#16 implementation decisions, architecture, and gotchas (March 2026)
type: project
---

Features #16 (Heroku Cost Inventory), #15 (Cost Insights + Pricing Model Publisher), and #14 (Dynamic Pricing Plans — Cost-Indexed) were all implemented in one session on 2026-03-31.

**Why:** Needed a sustainable margin management system before scaling paying customers.

**How to apply:** When touching pricing, cost tracking, or Heroku infra integration, refer to these patterns.

## Key Decisions

- Plan weight multipliers: manual decimal column on Plan (`weight_multiplier`); Starter=1x, Pro=2x, Business=4x, Enterprise=8x
- Annual pricing: monthly × 10 (`ANNUAL_FACTOR = 10` in `CostInsights::MarginEngine`) = 2 months free
- Heroku API: mock mode by default; live calls gated behind `heroku_cost_inventory` Flipper flag + `HEROKU_PLATFORM_API_TOKEN` env var
- Legacy customers: `legacy_v0` sentinel PricingModel (epoch `effective_from`); `Pricing::LegacyBackfillService` idempotent backfill
- OpenAI usage: Redis counters via `VendorUsage::OpenaiMeteringService.record(...)` → daily rollup to `ExternalServiceDailyUsage`
- PricingModel lifecycle: draft → published (immutable) → retired; `immutable?` check on edit/update/destroy

## Architecture

- `Heroku::PlatformClient` — mock_mode? when Flipper off or token blank
- `Heroku::EnvironmentClassifier` — pipeline stage takes precedence over app name patterns
- `CostInsights::TotalCalculator` — aggregates infra (production-only) + vendor + staff
- `CostInsights::MarginEngine` — deterministic; required_revenue / weight_sum = per_weight_unit; ceil throughout
- `Pricing::ModelCompiler` — validates inputs, calls MarginEngine, creates PricingModelPlanPrice in transaction
- `Pricing::StripePricePublisher` — creates Stripe::Price per plan/interval/currency; rolls back on failure
- `Pricing::ModelPublisher` — compile → Stripe → lock; all in PricingModel.transaction
- `Pricing::LegacyBackfillService` — idempotent; find_or_create_by(version: 'legacy_v0')

## Gotchas

- Pundit Scope inner class cannot call outer policy's `super_admin?` — must inline `user.present? && user.admin? && user.super_admin?`
- FK constraint: must delete `pricing_model_plan_prices` before deleting `plans` or `pricing_models` in tests
- `ExternalServiceDailyUsage#upsert_usage` uses `upsert` (skips validations) — intentional; rubocop disable added inline
- `Pricing::ModelPublisher` had unreachable code after `raise ActiveRecord::Rollback` — fixed by removing the dead `return` line
- `SecureHeaders` requires CSP keyword sources to be single-quoted in the array: `%w['self' 'unsafe-inline']` not `%w[self unsafe-inline]`
- `for_month` scope uses `month.all_month` (rubocop auto-corrected from `beginning_of_month..end_of_month`)
- Weight sum must be > 0 in MarginEngine (ArgumentError raised if all plans have 0 multiplier)
- `legacy_v0` sentinel: `effective_from = Time.zone.at(0)` (epoch) so it sorts before all real models in `PricingModel.current`

## Flipper Flags

- `heroku_cost_inventory` — enables live Heroku Platform API calls (disabled by default)
- `cost_insights_admin` — gates the cost insights admin dashboard (disabled by default)
- `cost_indexed_pricing` — gates Stripe price creation and cost-indexed pricing activation (disabled by default)

## Routes (all in admin namespace)

```ruby
resources :heroku_inventories, only: %i[index] do
  collection { get :coefficients; patch :update_coefficients; post :trigger_snapshot; post :trigger_rollup }
end
resource :cost_insights, only: %i[show] do
  collection { get :index; post :trigger_monthly_rollup }
end
resources :vendor_costs, only: %i[index new create edit update destroy]
resources :staff_costs, only: %i[index new create edit update destroy]
resources :margin_policies, only: %i[index new create edit update destroy] do
  member { patch :activate; patch :deactivate }
end
resources :pricing_models do
  member { get :preview; post :publish }
end
```

## Test Coverage Patterns That Worked

- Tear down `pricing_model_plan_prices` before deleting plans or pricing_models in teardown blocks
- Use `2.months.ago.beginning_of_month` for test dates to avoid fixture month collisions
- Space inventory service test: assert all apps have valid environments (don't assert specific environment — mock pipeline stage classification depends on app_id, not name)
