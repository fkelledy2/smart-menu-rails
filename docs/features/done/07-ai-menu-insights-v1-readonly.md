# AI Menu Insights (v1 – Read-only)

## Purpose
Provide operational insight that restaurants don’t have today, without auto-changing the menu.

This is a read-only “insights layer” derived from live dining signals.

## Current State (today)

- Analytics and reporting capabilities exist in the system (including materialized view patterns in other parts of the codebase).
- Voice commands are tracked (VoiceCommand persistence exists per voice docs).
- Order lifecycle and kitchen operational events exist.

Cross references:

- `docs/features/in-progress/voice-menus.md` (voice capture + outcomes)
- `docs/features/done/ordering.md` (analytics dashboard plan)

Gaps:

- No unified event stream to reliably feed insights.
- No dedicated “Insights” UI and no defined metrics set for menu-level insight.

## Scope (v1)

Insights to deliver (read-only):

- Slow movers (items that rarely get ordered)
- Prep-time bottlenecks (items that correlate with long prep times)
- Voice-trigger frequency (which items users attempt via voice)
- Abandonment points (where people stop short of ordering or paying)

## Metrics contract (v1)

### Dimensions and filters

- **Restaurant scope**
  - Insights are computed per restaurant.
- **Menu scope**
  - Default: include all menus for the restaurant.
  - Optional filter: restrict to a single menu.
- **Timezone**
  - All windows and groupings are evaluated in the restaurant timezone (fallback: app default timezone).

### Time windows

Use the same preset vocabulary as ordering analytics:

- Today
- Yesterday
- Last 7 Days
- Last 28 Days
- MTD
- Last Month
- Custom (start_date, end_date)

Notes:

- Window boundaries are inclusive of start and end dates.
- For “Today”, treat the window as midnight→now in restaurant timezone.

### Metric definitions

#### Slow movers

- **Population**
  - Menu items that are active/visible on the menu(s) in scope.
- **Order frequency (primary)**
  - `orders_with_item_count`: count of distinct orders in the window that include the menu item.
- **Quantity sold (secondary)**
  - `quantity_sold`: total units sold in the window.
- **Ranking**
  - Sort ascending by `orders_with_item_count`, then by `quantity_sold`, then by `menuitem_id` (stable).
- **Display**
  - Show: item name, orders_with_item_count, quantity_sold, share_of_orders (% of total orders in window).

#### Prep-time bottlenecks

- **Population**
  - Order items with measurable prep lifecycle timestamps.
- **Prep time definition**
  - `time_to_ready_seconds = ready_at - preparing_at`.
  - If `preparing_at` is unavailable, fallback to `ready_at - ordered_at`.
- **Aggregation**
  - `median_time_to_ready_seconds` per menu item.
  - `p90_time_to_ready_seconds` (optional, if easy) for outlier context.
  - `sample_size` = number of measurable order items for the menu item.
- **Ranking**
  - Sort descending by `median_time_to_ready_seconds`.
- **Outlier highlighting**
  - Flag as outlier if:
    - `sample_size >= 10`, and
    - `median_time_to_ready_seconds` is >= 1.5× the restaurant-level median across all items (same window), and
    - `median_time_to_ready_seconds` is >= 180 seconds.
- **Display**
  - Show: item name, median_time_to_ready, sample_size, (optional p90), and an outlier badge.

#### Voice-trigger frequency

- **Population**
  - Voice commands associated to a restaurant/menu/smartmenu context for the window.
- **Primary metric**
  - `voice_trigger_count`: number of voice commands that reference the menu item.
- **Success/failure rate**
  - `success_rate = success_count / (success_count + failure_count)`.
  - Success/failure is derived from the persisted voice command status/result.
- **Ranking**
  - Sort descending by `voice_trigger_count`.
- **Display**
  - Show: item name, voice_trigger_count, success_count, failure_count, success_rate.

#### Abandonment points (funnel)

This insight is explicitly event-driven.

- **Funnel steps**
  - menu_viewed
  - item_added
  - order_submitted
  - bill_requested
  - payment_started
  - payment_succeeded
- **Metrics**
  - `step_count`: number of unique sessions reaching the step.
  - `dropoff_count`: previous_step_count - step_count.
  - `dropoff_rate`: dropoff_count / previous_step_count.
- **Session identity**
  - Use a stable, anonymous session identifier (e.g. existing analytics session / cookie id) scoped to a restaurant/smartmenu.
- **Display**
  - Show counts and dropoff rates between each adjacent step.

### Edge cases and guardrails

- **No data**
  - Return empty lists and a clear “No data for selected window” message.
- **Low sample sizes**
  - For prep-time bottlenecks: hide outlier badges unless `sample_size >= 10`.
- **Data freshness**
  - v1 should tolerate eventual consistency (e.g. cached/rolled up data delayed by up to 15 minutes).
- **Permissions**
  - Only owners/managers can access insights (same security posture as ordering analytics).

## Non-goals (v1)

- No auto menu changes.
- No AI-driven A/B creation.
- No prescriptive optimization.

## Acceptance Criteria (GIVEN / WHEN / THEN)

### Slow movers

- GIVEN a menu with historical orders
  WHEN an owner views “Slow movers”
  THEN the system shows items sorted by lowest order frequency over a selectable window.

### Prep-time bottlenecks

- GIVEN order item timestamps are available (ordered → preparing → ready)
  WHEN an owner views “Prep-time bottlenecks”
  THEN the system ranks items by median time-to-ready and highlights outliers.

### Voice-trigger frequency

- GIVEN voice ordering is enabled for a restaurant
  WHEN an owner views voice insights
  THEN the system shows the top N items referenced by voice commands, including success/failure rate.

### Abandonment points

- GIVEN customers can browse and request bills/pay
  WHEN an owner views abandonment insights
  THEN the system shows drop-off at key steps:
  - menu viewed → item added
  - item added → order submitted
  - bill requested → payment started
  - payment started → payment succeeded

## Data sources (v1)

### Required (must exist)

- **Orders + order items**
  - Needed for slow movers.
- **Order lifecycle timestamps**
  - Needed for prep-time bottlenecks.
  - Source can be status transitions, kitchen events, or per-item timestamps (ordered/preparing/ready).
- **VoiceCommand persistence**
  - Needed for voice-trigger frequency.

### Optional (if available)

- **Unified event stream / analytics events**
  - Needed for full abandonment funnel including:
    - menu_viewed
    - item_added
    - payment_started
  - If these events are not yet tracked, v1 should still ship with a partial funnel using server-side milestones:
    - order_submitted (order status = ordered)
    - bill_requested (order status = billrequested)
    - payment_succeeded (order status = paid)

## UI surface (v1)

### Location

- Add an **Insights** tab in the owner dashboard area (restaurant context).

### Page structure

- Global filters:
  - Restaurant (if user has multiple)
  - Menu (optional)
  - Time window (presets + custom)
- Sections:
  - Slow movers table
  - Prep-time bottlenecks table
  - Voice-trigger frequency table
  - Abandonment funnel visualization (simple funnel table is acceptable in v1)

## Export contract (v1)

Exports should be for the current filter state (restaurant/menu/window).

### JSON

- `slow_movers`: array of
  - `menuitem_id`, `menuitem_name`, `orders_with_item_count`, `quantity_sold`, `share_of_orders`
- `prep_time_bottlenecks`: array of
  - `menuitem_id`, `menuitem_name`, `median_time_to_ready_seconds`, `sample_size`, `is_outlier`
- `voice_triggers`: array of
  - `menuitem_id`, `menuitem_name`, `voice_trigger_count`, `success_count`, `failure_count`, `success_rate`
- `abandonment_funnel`: array of
  - `step_key`, `step_count`, `dropoff_count`, `dropoff_rate`

### CSV

- Provide one CSV per section (slow_movers.csv, prep_time_bottlenecks.csv, voice_triggers.csv, abandonment_funnel.csv).
- Column names match JSON keys.

## Implementation notes (v1)

- Prefer cached queries or summary tables first.
- Consider materialized views for:
  - slow movers over daily rollups
  - prep time rollups by item/day
- Abandonment funnel requires an event stream; if unavailable, ship partial funnel based on order/payment milestones.

## Progress Checklist

- [ ] Define metrics contract and time windows
- [ ] Define data sources (orders, order items, voice commands)
- [ ] Add aggregation layer (materialized views or cached queries)
- [ ] Add UI surface (owner dashboard tab)
- [ ] Add export (CSV/JSON)
- [ ] Add tests for aggregations and edge cases (no data)
