# Table Wait Time Estimation

## Status
- Priority Rank: #12
- Category: Post-Launch
- Effort: L
- Dependencies: Floorplan Dashboard (#5 — completed) — shares table state concepts; `Tablesetting` model; `Ordr` model

## Problem Statement
Restaurants with high footfall regularly have walk-in customers waiting for a table. Staff must estimate wait times manually, leading to inaccurate quotes, customer frustration, and unnecessary walk-aways. A data-driven wait time estimation system gives staff accurate, real-time estimates based on current occupancy, service stage, and historical dining patterns — improving the walk-in experience and reducing lost revenue.

## Success Criteria
- Staff can view estimated wait times by party size on a live dashboard.
- Wait time estimates are based on current table occupancy state and historical dining patterns for the restaurant.
- Staff can add walk-in customers to a digital wait queue with name and party size.
- Wait time accuracy targets: within ±10 minutes for 80% of estimates after 30+ days of data.

## User Stories
- As a host/front-of-house staff member, I want accurate wait time estimates so I can quote customers confidently.
- As a restaurant manager, I want to see queue length and estimated seat times at a glance.
- As a waiting customer, I want to be added to a waitlist and notified when my table is ready.

## Functional Requirements
1. Staff dashboard shows current wait time estimates for standard party sizes (2, 4, 6, 8+).
2. Wait time is calculated using: current table occupancy + service stage progress + historical dining patterns for that restaurant, day of week, and hour.
3. `CustomerWaitQueue` model tracks: `restaurant_id`, `customer_name`, `customer_phone`, `party_size`, `joined_queue_at`, `estimated_wait_minutes`, `estimated_seat_time`, `queue_position`, `status` (waiting/notified/seated/cancelled/no_show), `seated_at`.
4. Staff can: add a customer to the queue, seat them (linking to a table), remove them, and mark as no-show.
5. Historical dining patterns stored in `dining_patterns` table (per restaurant, party size, day of week, hour): average/median/min/max dining duration, sample count.
6. Patterns are updated nightly via a Sidekiq cron job (`UpdateDiningPatternsJob`) from closed order data.
7. Real-time table occupancy sourced from active `Ordr` records and `Tablesetting` states (reuses floorplan data model where possible).
8. SMS notification to customer when their table is ready (stretch — requires Twilio; optional for v1).
9. Wait time estimates expire after 5 minutes and are recomputed from live table state.

## Non-Functional Requirements
- Wait time computation must complete within 2 seconds.
- Historical pattern queries use the replica DB (read-only, 15s timeout).
- SMS notifications require Twilio (or equivalent) — clearly flag as stretch goal gated by `receipt_sms` Flipper flag or separate `wait_time_sms` flag.

## Technical Notes

### Services
- `app/services/wait_time/estimation_service.rb`: computes wait time from occupancy + historical patterns.
- `app/services/wait_time/queue_manager.rb`: manages customer wait queue CRUD.
- `app/services/wait_time/pattern_updater.rb`: computes and persists dining patterns from historical orders.

### Models / Migrations
- `create_customer_wait_queue`: see schema above.
- `create_dining_patterns`: `restaurant_id`, `party_size`, `day_of_week`, `hour_of_day`, `average_duration_minutes`, `median_duration_minutes`, `sample_count`, `last_calculated_at`. Unique index on `[restaurant_id, party_size, day_of_week, hour_of_day]`.

### Jobs
- `app/jobs/update_dining_patterns_job.rb`: nightly Sidekiq cron job.
- `app/jobs/notify_wait_queue_customer_job.rb`: SMS notification (stretch).

### Policies
- `app/policies/customer_wait_queue_policy.rb`: staff and managers can manage the queue.

### Views
- Staff-facing wait time dashboard: `app/views/wait_times/show.html.erb`.
- Live update via ActionCable or Turbo Polling (simpler for v1).

### Flipper
- `wait_time_estimation` — per-restaurant opt-in.
- `wait_time_sms` — SMS notification stretch goal.

## Acceptance Criteria
1. Staff dashboard shows wait time estimates for party sizes 2, 4, 6, 8.
2. When a table becomes available (order closed), wait time estimates update within 30 seconds.
3. Adding a customer to the queue creates a `CustomerWaitQueue` record with `status: 'waiting'` and a computed `estimated_seat_time`.
4. Historical patterns are computed nightly and used in next-day estimates.
5. For a restaurant with no historical data, the system shows a sensible default estimate (e.g. 30 minutes) rather than an error.
6. Staff can mark a queued customer as "Seated" and the queue position updates for remaining customers.

## Out of Scope
- Customer-facing self-service queue join (post-launch).
- ML-based prediction model (post-launch — v1 uses simple weighted average).
- POS integration for real-time kitchen timing (post-launch).
- Integration with third-party reservation systems (post-launch).

## Open Questions
1. What is the canonical "table" model — `Tablesetting` or a new `RestaurantTable` model? This spec uses `Tablesetting` for consistency with the existing codebase. Confirm before migration work begins.
2. Should the wait time dashboard be part of the Floorplan view (#5) or a separate route? Recommended: separate route (`/restaurants/:id/wait_times`) with a link from the floorplan.
3. How should the system handle restaurants that don't yet have enough historical data? Default to a configurable estimate (admin-settable per restaurant, e.g. 30 minutes).
