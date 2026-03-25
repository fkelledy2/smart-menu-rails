---
name: Floorplan Dashboard v1 implementation decisions
description: Architecture, key patterns, and gotchas from the Floorplan Dashboard feature (March 2026)
type: project
---

Floorplan Dashboard (Feature #5) shipped 2026-03-25. Key decisions:

**Why:** Single-glance ops view for staff; real-time table state updates via ActionCable; differentiates from competitors.

**How to apply:** Reference when building table-state features, extending floorplan in Phase 2 (staff actions on tiles).

## Architecture decisions

- Route: `GET /restaurants/:id/floorplan` — member route on restaurants resource, `params[:id]` is the restaurant ID
- Policy: `FloorplanPolicy` — `authorize @restaurant, policy_class: FloorplanPolicy`; `show?` allows owner or active employee only, denies anonymous
- Feature flag: `floorplan_dashboard` — per-restaurant opt-in via Flipper
- Channel: `FloorplanChannel` streams on `"floorplan:restaurant:#{restaurant_id}"`
- Broadcast service: `FloorplanBroadcastService.broadcast_tile(tablesetting_id:, restaurant_id:)` — renders `_table_tile` partial via `ApplicationController.renderer`, broadcasts JSON `{ type: 'tile_update', tablesetting_id:, html: }` via ActionCable
- Stimulus controller: `floorplan_controller.js` (`data-controller="floorplan"`) — subscribes to FloorplanChannel, handles tile DOM replacement, client-side filtering, 1-min elapsed timer

## Database queries

- Two-step active-order query (no DISTINCT ON to avoid ORDER BY conflict with ordrs default scope):
  1. `Ordr.unscoped.where(restaurant_id: ...).where.not(status: excluded).group(:tablesetting_id).maximum(:id).values`
  2. `Ordr.unscoped.where(id: newest_ids).select(...)`
- Multi-order detection: `Ordr.unscoped.group(:tablesetting_id).having('COUNT(*) > 1').pluck(:tablesetting_id)`
- MUST use `Ordr.unscoped` for all GROUP BY / aggregate queries — `@restaurant.ordrs` carries default `order(orderedAt: :desc)` scope that conflicts with GROUP BY in PostgreSQL

## Model changes

- `Tablesetting`: added `has_many :ordrs, dependent: :nullify`
- `Ordr`: added `after_commit :broadcast_floorplan_tile_update, on: %i[create update]`
- `Ordrparticipant`: added `after_commit :broadcast_floorplan_tile_update, on: %i[create destroy]` — both callbacks call `FloorplanBroadcastService.broadcast_tile`

## Helper: FloorplansHelper

- `floorplan_status_badge_class(status)` — Bootstrap badge class per status
- `floorplan_status_label(status)` — human-readable label
- `floorplan_elapsed_label(created_at)` — "just now" / "N min" / "1h 30m"
- `floorplan_tile_delayed?(ordr)` — preparing/ready > 15 min, billrequested > 5 min

## Gotchas

- `DISTINCT ON (tablesetting_id)` requires first ORDER BY column to be `tablesetting_id` in PostgreSQL — use the two-step max(id) approach instead
- `@restaurant.ordrs` association carries `order(orderedAt: :desc, id: :desc)` default scope — always use `Ordr.unscoped` for GROUP BY queries
- `restaurant_kitchen_dashboard_path` does NOT exist — the correct helper is `kitchen_dashboard_restaurant_path(@restaurant)`
- `Employee` requires `eid` field in tests — use `eid: "EMP-#{SecureRandom.hex(4)}"` when creating test employees
- Broadcast payload format: `{ type: 'tile_update', tablesetting_id:, html: }` — Stimulus controller replaces `#table-tile-{id}` by `id` attribute on the tile div

## Test files

- `test/policies/floorplan_policy_test.rb`
- `test/helpers/floorplans_helper_test.rb`
- `test/controllers/floorplans_controller_test.rb`
- `test/services/floorplan_broadcast_service_test.rb`
