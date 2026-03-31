# Heroku Cost Inventory (Spaces + Pipelines)

## Status
- Priority Rank: #16
- Category: Post-Launch
- Effort: S
- Dependencies: Existing admin auth (`admin? && super_admin?`); `Admin::` namespace pattern; `HEROKU_PLATFORM_API_TOKEN` environment variable

## Problem Statement
mellow.menu's infrastructure costs across the `smart-menu` Heroku space are not automatically tracked. Without a reliable inventory of dyno types, add-on plans, and environment classification, the Cost Insights admin system (#12) cannot compute accurate infra costs for the pricing model. This spec defines the automated collection pipeline that feeds real Heroku costs into the pricing model engine.

## Success Criteria
- The system can list all apps in the `smart-menu` Heroku space and classify them by environment (production/staging/development/ephemeral).
- Daily inventory snapshots are captured and persisted.
- Monthly infra cost snapshots are computed per environment using internal cost coefficients.
- Admin+super_admin can view the inventory and cost breakdown.
- The pricing model (#15 Cost Insights → #14 Dynamic Pricing) can consume monthly infra cost totals as inputs.

## User Stories
- As a super admin, I want to see exactly what Heroku resources we're running so I can understand our infra cost.
- As the pricing engine, I need accurate monthly infra cost totals per environment to compute plan prices correctly.

## Functional Requirements
1. `Heroku::PlatformClient` wraps the `platform-api` gem with authenticated access and safe timeout/logging.
2. `Heroku::SpaceInventoryService.fetch(space_name: 'smart-menu')` returns a normalised list of apps with: app_id, app_name, pipeline_id, pipeline_stage, environment classification, formation (process types + sizes + counts), add-ons (service + plan name).
3. Environment classification rules (primary): pipeline stage maps to `production|staging|development|ephemeral|unknown`. Fallback: app name pattern matching.
4. `heroku_app_inventory_snapshots` table: `captured_at`, `space_name`, `app_id`, `app_name`, `pipeline_id`, `pipeline_stage`, `environment`, `formation_json` (jsonb), `addons_json` (jsonb). Indexes on `[space_name, captured_at]` and `[app_name, captured_at]`.
5. `infra_cost_snapshots` table: `month` (date, first of month), `provider` (`heroku`), `space_name`, `environment`, `estimated_monthly_cost_cents`, `app_count`, `formation_rollup_json` (jsonb), `addons_rollup_json` (jsonb), `created_by_user_id`, `updated_by_user_id`.
6. Internal coefficient tables: `heroku_dyno_size_costs` (`dyno_size`, `cost_cents_per_month`); `heroku_addon_plan_costs` (`addon_service`, `plan_name`, `cost_cents_per_month`).
7. Rollup algorithm: for each app → sum(formation quantity × dyno cost) + sum(addon plan cost); group by environment; persist into `infra_cost_snapshots`.
8. Ephemeral environments modelled with configurable inputs: `assumed_concurrent_instances`, `avg_lifetime_days`, `per_instance_monthly_cost_cents`.
9. Admin UI screens (under `Admin::` namespace): Space Inventory view, Cost Coefficients editor, Monthly Cost Snapshot viewer.
10. All screens gated to `admin? && super_admin?`.
11. Daily inventory snapshot job; monthly rollup job (also triggerable on-demand from admin UI).
12. `HEROKU_PLATFORM_API_TOKEN` stored in Rails credentials / environment variables. Not logged.

## Non-Functional Requirements
- Heroku API calls are read-only — no mutations to Heroku infrastructure.
- API token is never exposed in logs or error messages.
- Inventory capture must handle Heroku API rate limits gracefully (retry with backoff).
- Statement timeouts apply.

## Technical Notes

### Services
- `app/services/heroku/platform_client.rb`: wraps `platform-api` gem.
- `app/services/heroku/space_inventory_service.rb`: `fetch(space_name:)`.
- `app/services/heroku/environment_classifier.rb`: `classify(pipeline_stage:, app_name:)`.
- `app/services/heroku/cost_rollup_service.rb`: computes monthly totals from snapshots + coefficients.

### Jobs
- `app/jobs/heroku_inventory_snapshot_job.rb`: daily, captures and persists inventory.
- `app/jobs/heroku_monthly_cost_rollup_job.rb`: runs at month end or on-demand.

### Models / Migrations
- `create_heroku_app_inventory_snapshots`: see schema above.
- `create_infra_cost_snapshots`: see schema above.
- `create_heroku_dyno_size_costs`: `dyno_size:string unique`, `cost_cents_per_month:integer`.
- `create_heroku_addon_plan_costs`: `addon_service:string`, `plan_name:string`, `cost_cents_per_month:integer`. Unique on `[addon_service, plan_name]`.

### Policies
- `app/policies/admin/heroku_inventory_policy.rb`: `admin? && super_admin?`.

### Gems
- Add `platform-api` gem to `Gemfile`.

### Flipper
- `heroku_cost_inventory` — enable before cost insights admin screens go live.

## Acceptance Criteria
1. `Heroku::SpaceInventoryService.fetch(space_name: 'smart-menu')` returns a list of apps with environment classification without errors.
2. `HerokuInventorySnapshotJob` creates `heroku_app_inventory_snapshots` records for all apps in the space.
3. Production apps classified as `production`; staging apps as `staging`; review apps as `ephemeral`.
4. Monthly rollup computes `estimated_monthly_cost_cents` per environment and persists to `infra_cost_snapshots`.
5. Super admin can view the inventory table and the monthly cost breakdown in the admin UI.
6. `HEROKU_PLATFORM_API_TOKEN` is not present in any log output.
7. Non-super_admin user cannot access inventory admin pages (returns 403 or redirect).

## Out of Scope
- Pulling actual invoice totals from Heroku billing exports (manual coefficient approach in v1).
- Multi-space aggregation (single `smart-menu` space in v1).
- Non-Heroku infrastructure providers.

## Open Questions
1. What are the current dyno sizes and add-on plans in the `smart-menu` space? An initial audit is needed to populate the coefficient tables before the first rollup.
2. How frequently should inventory snapshots be retained before pruning? Recommend: keep 90 days of daily snapshots, then archive.
3. Should the `HEROKU_PLATFORM_API_TOKEN` be scoped to read-only permissions? Yes — provision a read-only OAuth token from the Heroku Platform API.
