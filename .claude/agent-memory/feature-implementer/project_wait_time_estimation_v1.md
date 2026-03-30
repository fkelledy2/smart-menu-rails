---
name: Wait Time Estimation v1
description: Table Wait Time Estimation v1: queue model, estimation service, pattern updater, cron job, route structure, upsert gotcha, replica fallback pattern (March 2026)
type: project
---

Wait Time Estimation (#13) shipped 2026-03-29.

**Architecture decisions:**
- `CustomerWaitQueue` model: string `status` column (not enum) with check constraint; STATUSES constant for inclusion validation
- `DiningPattern` model: unique index on [restaurant_id, party_size, day_of_week, hour_of_day] enforced at both DB and AR uniqueness validation levels
- `WaitTime::EstimationService`: uses `ApplicationRecord.on_replica` (not raw `connected_to`) so fallback to primary works in test
- `WaitTime::QueueManager`: Result struct pattern (Struct.new with keyword_init: true)
- `WaitTime::PatternUpdater`: uses `DiningPattern.upsert` with `unique_by` + `update_only` — rubocop disable comment needed for `Rails/SkipsModelValidations`

**Upsert gotcha:** `DiningPattern.upsert` with `update_only:` must NOT include `updated_at` in the update_only list — Rails adds it automatically to the full hash and Postgres rejects `multiple assignments to same column "updated_at"`.

**Bucket test gotcha:** Pattern updater tests must pin all test orders to the same `[party_size, day_of_week, hour_of_day]` bucket. If orders span multiple days/hours (e.g., "5 hours ago" staggered), each lands in a different bucket and none meet MIN_SAMPLE_SIZE. Fix: use `anchor - (i * 7).days` to keep same day-of-week + hour across weeks.

**Route naming:** Member routes inside `resources :restaurants` produce `wait_times_restaurant_path` (not `restaurant_wait_times_path`). Verify with `bin/rails routes | grep wait_time`.

**Replica usage:** Always use `ApplicationRecord.on_replica { ... }` (not `ActiveRecord::Base.connected_to(role: :reading)`) — the `on_replica` wrapper has fallback to primary for environments where replica is unavailable (test, dev).

**Pundit pattern for custom actions:** When `authorize @restaurant, policy_class: WaitTimePolicy` is used, Pundit derives the action name from the controller method (`seat_queue_entry` → `seat_queue_entry?`). Ensure the policy has matching method names.

**Asset manifest:** New Stimulus controllers must be added to `app/assets/config/manifest.js` or controller tests fail with "Asset not declared to be precompiled".

**Flipper flags introduced:**
- `wait_time_estimation` — disabled by default; per-restaurant opt-in
- `wait_time_sms` — disabled by default; requires Twilio credentials

**Cron job:** `update_dining_patterns` runs 2am UTC nightly in `low_priority` queue.

**Why:** High-footfall restaurants needed accurate walk-in wait time quotes and a digital queue to reduce walk-aways. Historical patterns (90-day lookback, per restaurant/party_size/day/hour) combined with live occupancy data give ±10 min accuracy after 30+ days.
