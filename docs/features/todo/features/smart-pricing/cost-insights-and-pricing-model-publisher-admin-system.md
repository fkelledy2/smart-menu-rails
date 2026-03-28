# Cost Insights + Pricing Model Publisher (Admin System)

## Status
- Priority Rank: #15
- Category: Post-Launch
- Effort: L
- Dependencies: Heroku Cost Inventory (#16), existing `admin?` and `super_admin?` predicates, existing `Admin::` namespace pattern

## Problem Statement
mellow.menu has no consolidated view of its running costs across infrastructure, third-party APIs, and staff. Without this visibility, pricing decisions are made on gut feel rather than data, making it impossible to maintain sustainable gross margins as the platform scales. This admin system gives super admins a unified cost picture and the ability to publish versioned pricing models that drive subscription prices for new customers.

## Success Criteria
- Super admins can view a monthly cost dashboard showing Heroku (from #13), vendor costs (OpenAI, DeepL, Google Vision, Stripe fees), and staff/support costs.
- Super admins can enter monthly staff and support costs manually.
- Super admins can configure the target gross margin.
- Super admins can preview computed plan prices before publishing.
- Super admins can publish a pricing model version, triggering Stripe Price creation.
- All screens are under `Admin::` namespace, inaccessible to non-super-admins.

## User Stories
- As a super admin, I want to see a monthly breakdown of what it costs to run mellow.menu so I can make informed pricing decisions.
- As a super admin, I want to publish a new pricing model version and have Stripe prices created automatically.
- As an engineer, I want vendor usage data automatically collected daily so manual entry is minimal.

## Functional Requirements
1. All admin screens implemented under `Admin::` namespace, not Madmin. Access requires `current_user.admin? && current_user.super_admin?`.
2. `external_service_daily_usages` table: `date`, `service`, `dimension`, `units`, `unit_type`, `restaurant_id` (nullable), `metadata` (jsonb). Unique index on `[date, service, dimension, restaurant_id]`.
3. `external_service_monthly_costs` table: `month`, `service`, `currency`, `amount_cents`, `source` (enum: manual/api_ingest/csv_import), `notes`, `evidence` (jsonb), `created_by_user_id`. Unique index on `[month, service, currency]`.
4. `staff_cost_snapshots` table: `month`, `currency`, `support_cost_cents`, `staff_cost_cents`, `other_ops_cost_cents`, `notes`, `created_by_user_id`.
5. `profit_margin_policies` table: `key` (unique string, e.g. 'default'), `target_gross_margin_pct`, `floor_gross_margin_pct`, `status` (active/inactive), `created_by_user_id`.
6. Admin Screen 1 — Cost Insights Dashboard: month/currency selectors; cards showing Heroku total, vendor total, staff total, combined total, current margin policy.
7. Admin Screen 2 — Vendor Costs: table of services × months with inline edit/create. Notes and evidence fields.
8. Admin Screen 3 — Staff/Support Costs: monthly entry form for support and staff costs.
9. Admin Screen 4 — Margin Policy: set target and floor margin. Activate/deactivate policies.
10. Admin Screen 5 — Pricing Model Preview + Publish: create draft → preview computed prices → publish action with confirmation and optional reason field.
11. Daily background jobs auto-collect usage for: DeepL (via usage API), OpenAI (via internal instrumentation), Google Vision (via internal instrumentation). Stripe fees via manual entry in v1.
12. Monthly rollup job computes `external_service_monthly_costs` totals from daily usages.
13. Publishing a pricing model triggers Stripe Price creation (delegating to `real-dynamic-pricing-plans-cost-indexed.md` spec).
14. Publish action is logged with `admin_user_id`, `published_at`, and optional `reason`.

## Non-Functional Requirements
- All admin screens require `admin? && super_admin?`. No `admin?`-only access.
- Cost data is never exposed to non-super-admins.
- Published pricing models are immutable after publication.
- Statement timeouts apply (5s primary, 15s replica).
- Daily usage ingestion jobs must handle API errors gracefully and retry.

## Technical Notes

### Services
- `app/services/cost_insights/total_calculator.rb`: aggregates infra + vendor + staff costs for a given month/currency.
- `app/services/cost_insights/margin_engine.rb`: computes required revenue and plan prices from total cost + margin target.
- `app/services/vendor_usage/deepl_ingestion_service.rb`: polls DeepL usage API.
- `app/services/vendor_usage/openai_metering_service.rb`: instruments internal OpenAI calls.
- `app/services/vendor_usage/google_vision_metering_service.rb`: instruments internal Vision calls.

### Jobs
- `app/jobs/deepl_usage_ingestion_job.rb`: daily.
- `app/jobs/openai_usage_rollup_job.rb`: daily.
- `app/jobs/monthly_cost_rollup_job.rb`: runs at month end or on-demand.

### Policies
- `app/policies/admin/cost_insights_policy.rb`: `admin? && super_admin?` for all actions.

### Controllers
- `app/controllers/admin/cost_insights_controller.rb`: dashboard.
- `app/controllers/admin/vendor_costs_controller.rb`: CRUD for `external_service_monthly_costs`.
- `app/controllers/admin/staff_costs_controller.rb`: CRUD for `staff_cost_snapshots`.
- `app/controllers/admin/margin_policies_controller.rb`: CRUD for `profit_margin_policies`.
- `app/controllers/admin/pricing_model_previews_controller.rb`: preview + publish.

### Flipper
- `cost_insights_admin` — enable admin screens before full pricing model rollout.

## Acceptance Criteria
1. Super admin can view the monthly cost dashboard with a correct total across all cost categories.
2. Super admin can enter a staff cost for a given month; it appears in the total.
3. DeepL daily usage ingestion job populates `external_service_daily_usages` records.
4. Super admin can create a draft pricing model, preview computed prices, and publish.
5. Publish creates Stripe Price records and marks the model as published (immutable).
6. A non-super_admin user cannot access any `/admin/cost_insights` or pricing model pages (returns 403).
7. Re-attempting to edit a published pricing model returns an error.

## Out of Scope
- Fully automated invoice ingestion from all vendors (v1 uses manual entry for most).
- Regional pricing beyond EUR/USD.
- Non-Heroku infrastructure providers.

## Open Questions
1. Which OpenAI model usage dimensions need to be tracked (tokens by model, image generation calls, etc.)? Confirm the list with engineering to ensure instrumentation covers all cost-driving calls.
2. Should Stripe fee ingestion in v1 be manual or via the Stripe Balance API? Recommend: manual monthly entry in v1, automated via Stripe API in v2.
3. What is the plan weight / allocation model used in `MarginEngine`? Requires a product decision (see dynamic pricing spec open questions).
