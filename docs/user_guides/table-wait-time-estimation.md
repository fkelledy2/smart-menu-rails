# Table Wait Time Estimation — User Guide

## Overview

The Wait Time Estimation feature gives front-of-house staff a live dashboard showing estimated wait times for walk-in customers, plus a digital queue to manage who is waiting and when they get seated. Estimates are powered by live table occupancy data and nightly-computed historical dining patterns.

## Who This Is For

Restaurant owners and any active employee of that restaurant. Customers do not have access to this view.

## Prerequisites

- You must be logged in as a staff member, manager, or owner for the restaurant.
- The `wait_time_estimation` Flipper feature flag must be enabled for your restaurant. Contact mellow.menu support to enable it.

## How To Use

### Opening the Dashboard

1. Sign in to your restaurant's staff interface.
2. In the restaurant sidebar, open the **Operations** section and click **Wait Times** (or navigate to `/restaurants/[your-restaurant-id]/wait_times`). The dashboard opens in a new tab.

### Reading Wait Time Estimates

The **Current Wait Estimates** card on the left shows estimated wait times for the four standard party sizes: 2, 4, 6, and 8 guests.

| Display | Meaning |
|---|---|
| "Available now" (green) | A suitable table is free right now |
| "~N min" (orange) | All suitable tables are occupied; this is how long until one becomes free |

**About default estimates:** When your restaurant does not yet have enough historical dining data (typically the first 3–4 weeks of use), estimates fall back to a conservative 30-minute default. A "Default estimate (insufficient data)" badge appears on the estimates card when this is the case. Estimates become more accurate as order history accumulates.

### Adding a Guest to the Queue

The **Add to Queue** form below the estimates card lets you record walk-in customers waiting for a table:

1. Enter the **Guest Name** (required) — e.g. "Smith party"
2. Enter the **Party Size** (required) — number of guests
3. Optionally enter a **Phone number** — used for SMS notification when a table is ready (SMS requires the `wait_time_sms` flag to be enabled separately)
4. Click **Add to Queue**

The guest is immediately assigned a position and an estimated seat time.

### Managing the Queue

The **Current Queue** panel on the right lists all active queue entries in order. Each entry shows:

- Position number
- Guest name and party size
- How long ago they joined the queue
- Remaining estimated wait (highlighted orange when nearly due, red if overdue)
- Phone number (if provided)

Each entry has three action buttons:

| Button | Action |
|---|---|
| Seat (green) | Marks the guest as seated. Optionally assign them to a specific table. |
| No-show (orange) | Removes the entry and reorders the remaining queue. |
| Remove (red) | Cancels the entry and reorders the remaining queue. |

## Key Concepts

**Wait time estimate** — the time in minutes before a suitable table is likely to become free. Computed from live occupancy data combined with historical dining patterns for the current day and time.

**Historical pattern** — an average dining duration computed from your restaurant's closed orders, broken down by party size, day of week, and hour of day. Updated nightly. Requires at least 5 orders in a given bucket to be used.

**Default estimate** — the 30-minute fallback value used when there is insufficient historical data. A badge on the estimates card indicates when the default is in use.

**Queue position** — the order in which a waiting guest will be seated. Positions reorder automatically when guests are seated, removed, or marked as no-shows.

## Tips & Best Practices

- Keep the Wait Times dashboard open on a tablet at the host stand for quick reference during busy periods.
- Record all walk-in guests in the queue, even when you can seat them immediately — it builds the historical data that improves future estimates.
- Use the phone field whenever guests provide a number. SMS notification (when enabled) frees staff from having to manually find and notify waiting guests.
- The estimates card refreshes automatically every 5 minutes. You do not need to reload the page.

## Limitations & Known Constraints

- Estimates are only as accurate as your historical data. New restaurants will see the 30-minute default until enough data has accumulated (typically 3–4 weeks).
- SMS notifications require the `wait_time_sms` Flipper flag and Twilio credentials to be configured. Contact mellow.menu support to enable this.
- The dashboard shows a single unified queue. Multiple separate queues (e.g. bar seating vs. table seating) are not supported in v1.
- Wait time estimates are not visible to customers in v1. This is a staff-only tool.

## Frequently Asked Questions

**Q: The estimates say "Default estimate (insufficient data)". What does this mean?**
A: Your restaurant does not yet have enough historical order data for the system to compute a live estimate. A 30-minute default is shown as a conservative placeholder. Estimates will improve after 3–4 weeks of regular use.

**Q: A guest who was added to the queue has left without being seated. How do I remove them?**
A: Click the red Remove button on their queue entry. The queue reorders automatically.

**Q: Can customers see their own wait time estimate?**
A: Not in v1. The wait time dashboard is staff-only. Customers can be verbally informed by staff.

**Q: How do I enable this feature for my restaurant?**
A: Contact mellow.menu support to enable the `wait_time_estimation` Flipper flag for your account.
