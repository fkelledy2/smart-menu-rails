# Menu Experiments (A/B + Time-Boxed) (v1)

## Status
- Priority Rank: #11 (elevated from #14 — MenuVersion dependency resolved; CRM Sales Funnel inserted at #9 shifts all downstream ranks)
- Category: Post-Launch
- Effort: M
- Dependencies: `MenuVersion` system (BUILT — see `menu-versioning-system.md`); existing `Menu`, `MenuItem`, `Smartmenu` models; `DiningSession` from QR Security (#1)

> **Dependency resolved**: The MenuVersion system previously flagged as "not yet built" is fully implemented in the codebase: `app/models/menu_version.rb`, four supporting services, a versions controller, DB schema, and tests all exist. Menu Experiments can proceed once QR Security (#1) is shipped (required for `DiningSession` on which experiment assignment is stored).

---

## Problem Statement
Restaurant owners currently have no way to test whether menu changes — a new item description, a reorganised section, a price adjustment — actually improve customer ordering behaviour. Without experimentation infrastructure, every menu change is a blind bet. Menu A/B experiments allow restaurants to run safe, time-boxed tests between two menu versions and measure the impact on ordering patterns before committing to changes.

## Success Criteria
- Restaurant owners can define an experiment: a control version, a variant version, a split percentage, and a time window.
- Customers are deterministically and consistently assigned to control or variant for the duration of the experiment.
- Exposure events are logged per session asynchronously.
- The system serves the correct menu version based on experiment assignment.
- After the experiment window ends, the system automatically reverts to the default active version — no manual intervention required.
- Restaurant owners can view exposure counts per variant.

## User Stories
- As a restaurant owner, I want to test two versions of my menu simultaneously so I can see which performs better before committing to the change.
- As a customer, I want a consistent menu experience within a dining session — I should not see different items appear or disappear.
- As a restaurant owner, I want the experiment to end automatically at the specified time, returning all customers to the standard menu without my intervention.
- As a restaurant owner, I want to be able to pause or end an experiment early if something goes wrong.

## Functional Requirements
1. `menu_experiments` table: `menu_id`, `control_version_id` (FK → `menu_versions`), `variant_version_id` (FK → `menu_versions`), `allocation_pct` (integer, default 50, range 1–99), `starts_at` (datetime), `ends_at` (datetime), `status` (enum: `draft`/`active`/`paused`/`ended`), `created_by_user_id`.
2. Version assignment: at SmartMenu render time, if an active experiment exists for the menu, assign the customer to control or variant using a stable hash of `dining_session.session_token`. Assignment must be deterministic — the same session token always maps to the same version within the experiment window.
3. Assignment is stored on the `DiningSession` record: `menu_experiment_id` and `assigned_version_id` columns.
4. Exposure logging: when a customer is served a menu version as part of an active experiment, enqueue an async job to record `menu_experiment_exposures`: `menu_experiment_id`, `assigned_version_id`, `dining_session_id`, `exposed_at`. Exposure logging must not block menu rendering.
5. Safety: when `ends_at` has passed, `menu.active_menu_version` resolution (which already exists in `Menu#active_menu_version`) returns the default active version. No additional cleanup is required at serve time.
6. `EndExpiredMenuExperimentsJob` runs on a Sidekiq cron (every 15 minutes) and sets experiments to `ended` status when their `ends_at` has elapsed. This is a belt-and-suspenders audit trail step — the serve-time behaviour is already safe regardless.
7. Experiment creation validates:
   - Menu has at least two `MenuVersion` records.
   - `starts_at` is in the future.
   - `ends_at` is after `starts_at`.
   - `allocation_pct` is between 1 and 99.
   - No other active or scheduled experiment overlaps this time window for the same menu (no overlapping `[starts_at, ends_at]` for the same `menu_id`).
8. Restaurant owner UI: create/edit/pause/end experiments; view exposure count per variant.

## Non-Functional Requirements
- Version assignment computation must add less than 10ms to SmartMenu render time. The hash-based algorithm (`Digest::MD5`) is O(1) and meets this comfortably.
- Exposure logging is asynchronous — enqueue a Sidekiq job; do not block the render path.
- Experiments for the same menu cannot overlap in time (enforced by DB-level uniqueness and model validation).
- Feature flag (`menu_experiments` Flipper flag, per-restaurant) must be enabled for experiments to activate. Unflagged restaurants serve their default menu with no experiment check.

## Technical Notes

### Services
- `app/services/menu_experiments/version_assignment_service.rb`
  - Input: `dining_session`, `menu_experiment`
  - Algorithm: `Digest::MD5.hexdigest("#{dining_session.session_token}:#{menu_experiment.id}").to_i(16) % 100 < menu_experiment.allocation_pct`
  - Returns: `control_version` or `variant_version` (a `MenuVersion` record)
  - Must be pure (no writes, no side effects) — it is called in the render path

- `app/services/menu_experiments/exposure_logger.rb`
  - Enqueues `MenuExperimentExposureJob` with session/experiment/version IDs
  - Must not raise — log and swallow errors to protect render path

### Jobs
- `app/jobs/menu_experiment_exposure_job.rb`
  - Creates `MenuExperimentExposure` record
  - Idempotent — no-op if a record for `[dining_session_id, menu_experiment_id]` already exists
  - Sidekiq retry: 3 attempts, exponential backoff

- `app/jobs/end_expired_menu_experiments_job.rb`
  - Sidekiq cron, every 15 minutes
  - Finds `active` experiments where `ends_at < Time.current`
  - Updates `status` to `ended` in a single batch `update_all`
  - Logs count of experiments ended

### Models / Migrations

**`create_menu_experiments`:**
```ruby
create_table :menu_experiments do |t|
  t.references :menu, null: false, foreign_key: true
  t.references :control_version, null: false, foreign_key: { to_table: :menu_versions }
  t.references :variant_version, null: false, foreign_key: { to_table: :menu_versions }
  t.references :created_by_user, foreign_key: { to_table: :users }
  t.integer :allocation_pct, null: false, default: 50
  t.datetime :starts_at, null: false
  t.datetime :ends_at, null: false
  t.integer :status, null: false, default: 0  # enum
  t.timestamps
end
add_index :menu_experiments, [:menu_id, :status]
add_index :menu_experiments, [:menu_id, :starts_at, :ends_at]
```

**`create_menu_experiment_exposures`:**
```ruby
create_table :menu_experiment_exposures do |t|
  t.references :menu_experiment, null: false, foreign_key: true
  t.references :assigned_version, null: false, foreign_key: { to_table: :menu_versions }
  t.references :dining_session, null: false, foreign_key: true
  t.datetime :exposed_at, null: false
  t.timestamps
end
add_index :menu_experiment_exposures, [:menu_experiment_id, :assigned_version_id]
add_index :menu_experiment_exposures, [:dining_session_id, :menu_experiment_id], unique: true, name: 'idx_exposures_session_experiment'
```

**`add_experiment_fields_to_dining_sessions`:**
```ruby
add_reference :dining_sessions, :menu_experiment, foreign_key: { to_table: :menu_experiments }
add_reference :dining_sessions, :assigned_version, foreign_key: { to_table: :menu_versions }
```

### Serving Logic in SmartMenu Render Path

In `Smartmenus::SmartmenuController` (or equivalent) — inside the action that resolves which menu content to render:

```ruby
# Pseudocode — adapt to actual controller structure
if Flipper.enabled?(:menu_experiments, current_restaurant)
  active_experiment = MenuExperiment.active_for_menu(@menu, at: Time.current)
  if active_experiment && @dining_session
    version = MenuExperiments::VersionAssignmentService.assign(
      dining_session: @dining_session,
      menu_experiment: active_experiment,
    )
    @dining_session.update_columns(
      menu_experiment_id: active_experiment.id,
      assigned_version_id: version.id,
    ) if @dining_session.menu_experiment_id.nil?
    MenuExperiments::ExposureLogger.log(@dining_session, active_experiment, version)
    @menu_version_snapshot = version.snapshot_json
  end
end
# Fall through to standard active_menu_version resolution if no experiment
```

The snapshot data from `version.snapshot_json` is read directly — do NOT call `MenuVersionApplyService.apply_snapshot!` in the render path (that service is for rollback preview flows and modifies in-memory AR objects).

### Policies
- `app/policies/menu_experiment_policy.rb`
  - `index?`, `show?`, `create?`, `update?`, `destroy?` — restaurant managers/owners only
  - Scope: `MenuExperiment.where(menu_id: restaurant.menu_ids)`

### Flipper
- `menu_experiments` — per-restaurant opt-in flag. Gate must be checked at both experiment creation and serve time.

---

## Acceptance Criteria
1. A restaurant owner can create an experiment: selects two existing menu versions, sets an allocation percentage and a time window.
2. Validation rejects: overlapping experiments for the same menu, start time in the past, end time before start, allocation outside 1–99%, fewer than two versions available.
3. A customer assigned to the variant sees the variant menu content consistently for the full duration of their dining session. Refreshing the page does not change their assigned version.
4. A `menu_experiment_exposures` record exists for each unique `[dining_session_id, menu_experiment_id]` combination where the customer was served under an active experiment.
5. After `ends_at`, all new customers see the default active menu version regardless of any prior experiment assignment.
6. `EndExpiredMenuExperimentsJob` sets `status = ended` for all experiments whose `ends_at < Time.current`. Running it twice for the same experiment is a no-op.
7. The SmartMenu render time overhead introduced by experiment assignment is less than 10ms (measurable via `ActiveSupport::Notifications` instrumentation).
8. A restaurant with the `menu_experiments` Flipper flag disabled sees no experiment code path executed.

---

## Out of Scope
- Multi-variant experiments (more than 2 variants) — post-launch.
- AI-suggested experiment variants — post-launch.
- Auto-optimisation / winner promotion based on results — post-launch.
- Statistical significance calculation — manual analysis by restaurant owner for v1.
- Localised content in experiment snapshots — `snapshot_json` does not include locale records; live localisation is used at render time (known limitation, documented in `menu-versioning-system.md`).

---

## Open Questions
1. Should experiments be limited to specific plan tiers (e.g. Pro/Business), or available on all plans? Recommend Pro and above to incentivise upgrade.
2. What analytics are shown to the restaurant owner? Minimum for v1: exposure count per variant + order count per variant (requires joining `menu_experiment_exposures` → `dining_sessions` → `ordrs`). Statistical significance is out of scope.
3. Should `allocation_pct` be editable on an in-progress experiment, or locked once `status = active`? Recommend locked — changing mid-experiment invalidates prior assignment consistency.
