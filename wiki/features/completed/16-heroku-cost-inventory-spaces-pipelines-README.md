# Heroku Cost Inventory — User Guide

**Feature**: #16 Heroku Cost Inventory (Spaces + Pipelines)
**Status**: Completed 2026-03-31
**Flipper flag**: `heroku_cost_inventory`

---

## What This Feature Does

This feature gives Smart Menu admins a live view of every Heroku app running in the `smart-menu` private space. It captures app formations (dynos), add-ons, and pipeline stage (production/staging/development/ephemeral), then uses a coefficient table of dyno-size costs and add-on plan costs to estimate monthly infrastructure spend.

---

## How to Access

Navigate to **Admin → Heroku Inventories** (`/admin/heroku_inventories`).

You must be a `super_admin` to access this section. If your account has `admin: true` but not `super_admin: true`, you will receive a 403.

---

## Key Screens

### Inventory Index

Lists the most-recent snapshot per app. Columns include:

- **App / Pipeline** — the Heroku app name and which pipeline it belongs to
- **Environment** — classified as `production`, `staging`, `development`, or `ephemeral`
- **Dynos** — the formation rollup (e.g., `web×2 eco, worker×1 standard-1x`)
- **Add-ons** — the add-on plan list
- **Captured At** — when the snapshot was taken

### Cost Coefficients

The `/admin/heroku_inventories/coefficients` page lets you set the monthly cost (in cents) for each:

- **Dyno size** (e.g., `eco`, `basic`, `standard-1x`, `standard-2x`, `performance-m`, `performance-l`)
- **Add-on plan** (indexed by `addon_service:plan_name`, e.g., `heroku-postgres:essential-0`)

Update coefficients via the form and click **Save Coefficients**. The next cost rollup will use the new values.

---

## Capturing a Snapshot

### Automatic (via Sidekiq cron)

`HerokuInventorySnapshotJob` runs on a cron schedule and automatically captures the current state of the `smart-menu` space.

### Manual Trigger

From the Inventory index page, click **Trigger Snapshot**. This enqueues `HerokuInventorySnapshotJob` immediately.

You can also trigger via Rails console:

```ruby
HerokuInventorySnapshotJob.perform_now
```

---

## Running a Cost Rollup

A cost rollup reads the latest snapshots per app, groups them by environment, applies the dyno and add-on coefficients, and writes `InfraCostSnapshot` records. These records are then consumed by the Cost Insights dashboard (#15).

### Automatic

`HerokuMonthlyCostRollupJob` runs at month-end.

### Manual Trigger

From the Inventory index, click **Trigger Rollup**. Or via console:

```ruby
HerokuMonthlyCostRollupJob.perform_now(month: Date.current.beginning_of_month)
```

---

## Enabling the Live Heroku API

By default the feature runs in **mock mode** — it simulates a small set of apps and returns realistic data without calling the real Heroku Platform API. This is the safe default for development and test environments.

To enable live API calls:

1. Set the environment variable:
   ```
   HEROKU_PLATFORM_API_TOKEN=<your-token>
   ```
2. Enable the Flipper flag:
   ```ruby
   Flipper.enable(:heroku_cost_inventory)
   ```

When both are present, `Heroku::PlatformClient` will issue real API requests to `api.heroku.com`.

---

## Environment Classification

Apps are classified into four environments using their **pipeline stage** (takes precedence) then **app name pattern**:

| Pipeline Stage | Environment |
|---------------|-------------|
| `production`  | `production` |
| `staging`     | `staging` |
| `development` | `development` |
| `review`      | `ephemeral` |

App name patterns (fallback when no pipeline stage):
- Contains `production` or `prod` → `production`
- Contains `staging` or `stage` → `staging`
- Contains `review`, `pr-`, or `feature-` → `ephemeral`
- Otherwise → `development`

---

## Architecture Notes

- `Heroku::PlatformClient` — wraps `platform-api` gem; mock mode when Flipper flag is off or token is blank
- `Heroku::SpaceInventoryService` — fetches app list + formations + add-ons for a space
- `Heroku::EnvironmentClassifier` — maps pipeline stage/name to an environment string
- `Heroku::CostRollupService` — computes `InfraCostSnapshot` records from `HerokuAppInventorySnapshot` + coefficient tables
- Snapshots older than 90 days are automatically pruned by `HerokuInventorySnapshotJob`
