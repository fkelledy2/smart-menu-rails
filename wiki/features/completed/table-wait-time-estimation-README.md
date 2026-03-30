# Table Wait Time Estimation — User Guide

## Overview

The Wait Time Estimation feature gives front-of-house staff a live dashboard showing estimated wait times for walk-in customers, plus a digital queue to manage who is waiting and when they get seated. Estimates are powered by live table occupancy data and nightly-computed historical dining patterns.

---

## Enabling the Feature

The feature is disabled by default and is enabled per restaurant via Flipper.

**In the Flipper admin UI** (`/flipper`):
1. Find the flag `wait_time_estimation`.
2. Enable it for the specific restaurant (or globally).

SMS notifications are a separate opt-in flag: `wait_time_sms` (requires Twilio credentials — see below).

---

## Accessing the Dashboard

Once enabled, the dashboard is available at:

```
/restaurants/:id/wait_times
```

Staff can also navigate there from the Floorplan dashboard via the **Wait Times** button that appears in the header when the flag is enabled.

**Who can access it:** Restaurant owners and any active employee of that restaurant.

---

## Dashboard Layout

The dashboard has two panels:

### Left Panel — Wait Time Estimates

Shows estimated wait time for the four standard party sizes: **2, 4, 6, 8**.

- If a suitable free table is available right now → shows **"Available now"** in green.
- If all suitable tables are occupied → shows **~N min** (estimated remaining dining time of the soonest-finishing table).
- If the restaurant has no historical data yet → defaults to **30 minutes** as a conservative estimate.

Estimates automatically refresh every 5 minutes. The badge in the card header shows how long ago the last update ran.

### Left Panel — Add to Queue Form

Fields:
- **Guest Name** (required): e.g. "Smith party"
- **Party Size** (required): number of guests
- **Phone** (optional): used for SMS notification when table is ready

Click **Add to Queue** to enqueue the guest. They are immediately assigned a position and an estimated seat time.

### Right Panel — Current Queue

Lists all active queue entries in order. For each entry you see:
- Position number (badge)
- Guest name and party size
- How long ago they joined the queue
- Remaining estimated wait time (highlighted in orange when nearly due, red if overdue)
- Phone number (if provided)

#### Queue Actions

Each entry has three action buttons:

| Button | Action | Notes |
|--------|--------|-------|
| **Seat** (green) | Marks the guest as seated | Opens a dropdown to optionally assign them to a specific table. The queue reorders automatically. |
| Person-X (orange) | Mark as no-show | Removes from active queue; reorders remaining entries. |
| X (red) | Remove / Cancel | Removes from active queue; reorders remaining entries. |

---

## How Wait Times Are Calculated

### Real-time component

The system checks which tables (of sufficient capacity) are currently occupied. If any suitable table is free, the estimate is 0 (immediate seating). If all are occupied, it finds the one likely to finish soonest.

### Historical component

Each night at 2am UTC, `UpdateDiningPatternsJob` analyses all closed paid orders from the past 90 days and computes per-restaurant averages broken down by:
- Party size
- Day of week (Monday, Tuesday, etc.)
- Hour of day (0–23)

These patterns are stored in the `dining_patterns` table and used the next day to inform estimates. A bucket requires at least 3 orders (MIN_SAMPLE_SIZE) and at least 5 to be used in estimates (MIN_SAMPLE_THRESHOLD). Outlier orders longer than 10 hours are excluded.

**New restaurants** with no historical data receive a 30-minute default until enough data accumulates (typically 3–4 weeks of use).

### Accuracy target

The spec targets ±10 minutes accuracy for 80% of estimates after 30+ days of data.

---

## SMS Notifications (Stretch Goal)

When the `wait_time_sms` Flipper flag is enabled for a restaurant **and** Twilio credentials are configured, the `NotifyWaitQueueCustomerJob` can send an SMS to the guest's phone number.

**Required credentials** in Rails credentials:
```yaml
twilio:
  account_sid: "ACxxxxxxxxxxxxxxxx"
  auth_token: "xxxxxxxxxxxxxxxxxx"
  from_number: "+15550000000"
```

The SMS is triggered automatically when a guest is moved to **notified** status. Without the flag or credentials, the job logs and returns silently — no errors.

---

## Historical Pattern Backfill

To manually trigger pattern computation for a specific restaurant (e.g. after initial setup):

```ruby
UpdateDiningPatternsJob.perform_later(restaurant_id: <id>)
```

To recompute for all active restaurants:

```ruby
UpdateDiningPatternsJob.perform_later
```

---

## Operational Notes

- The cron job (`update_dining_patterns`) runs nightly at 2am UTC via Sidekiq scheduler.
- Pattern queries hit the read replica (with automatic fallback to primary).
- The wait time computation must complete within 2 seconds (standard for staff dashboards).
- All queue mutations (seat/no-show/cancel) reorder remaining queue positions atomically.

---

## Files Created

| File | Purpose |
|------|---------|
| `db/migrate/20260329220235_create_customer_wait_queues.rb` | Queue table migration |
| `db/migrate/20260329220244_create_dining_patterns.rb` | Patterns table migration |
| `app/models/customer_wait_queue.rb` | Queue record model |
| `app/models/dining_pattern.rb` | Historical patterns model |
| `app/services/wait_time/estimation_service.rb` | Wait time computation |
| `app/services/wait_time/queue_manager.rb` | Queue CRUD orchestration |
| `app/services/wait_time/pattern_updater.rb` | Nightly pattern computation |
| `app/jobs/update_dining_patterns_job.rb` | Nightly cron job |
| `app/jobs/notify_wait_queue_customer_job.rb` | SMS notification job (stretch) |
| `app/controllers/wait_times_controller.rb` | Dashboard controller |
| `app/policies/wait_time_policy.rb` | Dashboard authorization |
| `app/policies/customer_wait_queue_policy.rb` | Queue entry authorization |
| `app/views/wait_times/show.html.erb` | Dashboard view |
| `app/views/wait_times/_estimates.html.erb` | Estimates card partial |
| `app/views/wait_times/_queue_list.html.erb` | Queue list partial |
| `app/views/wait_times/_flash.html.erb` | Flash message partial |
| `app/javascript/controllers/wait_time_controller.js` | Stimulus auto-refresh controller |

---

## Flipper Flags

| Flag | Default | Purpose |
|------|---------|---------|
| `wait_time_estimation` | Disabled | Enable the dashboard per restaurant |
| `wait_time_sms` | Disabled | Enable SMS notification when table ready |
