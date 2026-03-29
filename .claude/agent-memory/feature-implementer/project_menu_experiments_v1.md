---
name: Menu Experiments A/B Testing v1
description: Menu Experiments v1 implementation decisions, architecture, Flipper flag, plan gate, and cron job (March 2026)
type: project
---

Menu Experiments (#12) shipped 2026-03-29. Key decisions:

- Experiment models: `MenuExperiment` (status enum prefix: `status_active?`, `status_draft?` etc.), `MenuExperimentExposure`
- `DiningSession` got two new nullable columns: `menu_experiment_id` and `assigned_version_id`
- Assignment is deterministic MD5 hash: `"#{session_token}:#{experiment_id}"`.to_i(16) % 100 < allocation_pct → variant
- `MenuExperiments::VersionAssignmentService` is pure — no writes, no enqueues — safe in render path
- `MenuExperiments::ExposureLogger` swallows all errors — never raises — protects render path
- Experiment serve logic inserted into `SmartmenusController#load_active_menu_version` via `resolve_experiment_version`
- Uses `snapshot_json` from `MenuVersion` directly — does NOT call `MenuVersionApplyService` in render path (that service modifies in-memory AR objects for rollback preview only)
- `EndExpiredMenuExperimentsJob` runs every 15 minutes (sidekiq.yml cron) using `update_all` batch — no callbacks fired
- Plan gate in `MenuExperimentPolicy`: `ELIGIBLE_PLAN_KEYS = %w[plan.pro.key plan.business.key]`
- Routes: nested under `resources :menus` → `resources :experiments, controller: 'menus/experiments'` with member routes `patch :pause` and `patch :end_experiment, path: 'end'`
- Flipper flag: `menu_experiments` — disabled by default, enable per restaurant
- UI: `menus/experiments/` views, sidebar link gated behind Flipper check in `_sidebar_2025.html.erb`
- No fixtures for `menu_experiments` or `menu_experiment_exposures` (empty fixture files) — all test setup inline via `create!`
- Added `pro` plan fixture with `key: plan.pro.key` to `test/fixtures/plans.yml`
- Test database could not be prepared during implementation due to Postgres.app trust auth permission dialog — migrations syntactically correct but not applied to dev/test DB at time of writing

**Why:** plan gate: Pro+ incentivises upgrade; allocation_pct locked once active: changing mid-experiment invalidates prior assignment consistency; no stats calculation: deferred to v2.
