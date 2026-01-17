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

## Progress Checklist

- [ ] Define metrics contract and time windows
- [ ] Define data sources (orders, order items, voice commands)
- [ ] Add aggregation layer (materialized views or cached queries)
- [ ] Add UI surface (owner dashboard tab)
- [ ] Add export (CSV/JSON)
- [ ] Add tests for aggregations and edge cases (no data)
