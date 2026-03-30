# Floorplan Dashboard (Real-Time Table Overview)

## Status
- Priority Rank: #5
- Category: Launch Enhancer
- Effort: M
- Dependencies: Existing `Tablesetting`, `Ordr`, `Ordrparticipant` models; ActionCable (existing infrastructure)

## Problem Statement
Restaurant staff currently have no single-glance operational view of all tables — their occupancy, order status, and service stage. Staff must navigate between individual order views or rely on verbal communication to understand floor state. This creates service delays and missed billing moments. A floorplan dashboard gives staff instant situational awareness and is a key differentiator against basic digital menu tools.

## Success Criteria
- Staff and managers can view all restaurant tables on a single dashboard screen.
- Each table tile shows: name, capacity, current order status, time since order opened, participant count, and payment state.
- The dashboard updates in real time when any order status changes — no full page reload required.
- Staff can filter to: active tables only, tables with bill requested, tables delayed beyond a threshold.
- The feature ships with auto-layout (grid by table name/number); custom drag-and-drop layout is post-launch.

## User Stories
- As a floor manager, I want to see all table statuses at a glance so I can proactively manage service.
- As a server, I want to know which tables have requested the bill so I can respond quickly.
- As staff, I want to see which tables have been waiting too long so I can intervene.
- As a restaurant manager, I want real-time visibility into order states so I can coach the team.

## Functional Requirements
1. A new route `GET /restaurants/:id/floorplan` renders the floorplan dashboard (staff and manager access only).
2. The dashboard loads all `Tablesetting` records for the restaurant plus their currently active `Ordr` (status not in `paid`, `closed`).
3. Each table tile displays: table name, capacity, order status chip (colour-coded), time since order opened (live counter), participant count, bill-requested badge, payment status badge.
4. Order status chips use the existing `Ordr.status` state machine: `opened` (grey), `ordered` (blue), `preparing` (orange), `ready` (green), `delivered` (muted green), `billrequested` (purple), `paid`/`closed` (faded).
5. "Attention" heuristic: a table tile is highlighted when order has been in `preparing` or `ready` for more than a configurable threshold (default: 15 minutes) or `billrequested` for more than 5 minutes.
6. Filters: "All tables", "Active only", "Bill requested", "Delayed". Filters apply client-side without server round-trip.
7. Real-time updates via ActionCable. On any order state change, a broadcast updates the specific table tile by `tablesetting_id`.
8. If a table has no active order, it shows as "Available" (green indicator).
9. Only one active order per table is displayed (the most recent non-closed order). If multiple exist, surface the most recent and log a warning.
10. Participant count sourced from `Ordrparticipant.count` per order — use counter cache or single grouped query to avoid N+1.

## Non-Functional Requirements
- Initial page load must complete within 5 seconds for restaurants with up to 50 tables.
- Real-time updates must propagate within 2 seconds of the triggering state change.
- Accessible: status chips must not rely on colour alone — include status text.
- Responsive: functional on tablet (minimum 768px width) — this is a staff-facing tool.
- Statement timeouts: floorplan query must complete within 5s primary DB limit.

## Technical Notes

### Controller
- `app/controllers/floorplans_controller.rb` — new controller.
- `authorize :floorplan, policy_class: FloorplanPolicy` — new Pundit policy.
- Single query: load all `Tablesetting` for restaurant; eager-load active `Ordr` with `Ordrparticipant` count; avoid N+1.

### Policy
- `app/policies/floorplan_policy.rb`: allow `show?` for users with `manager` or `staff` role on the restaurant.

### ActionCable
- Reuse or extend an existing restaurant-scoped channel.
- Recommended: create `FloorplanChannel` subscribing to `"floorplan:restaurant:#{restaurant.id}"`.
- Broadcast partial re-render of the table tile via Turbo Streams when order state changes.
- Broadcast triggers: `Ordr` after_commit on status change, `Ordrparticipant` after_commit.

### Views
- `app/views/floorplans/show.html.erb`: Stimulus controller (`floorplan_controller.js`) handles filter UI.
- `app/views/floorplans/_table_tile.html.erb`: ViewComponent or partial for the tile — rendered server-side and broadcast via Turbo Streams.

### Performance
- Add `ordrs.participants_count` counter cache if not already present.
- Consider `tablesettings.current_ordr_id` denormalised column to avoid join — add as optional optimisation if query performance warrants it.
- Replica DB for the initial page load query (read-only, acceptable for 15s timeout).

### Routes
```ruby
resources :restaurants do
  resource :floorplan, only: [:show]
end
```

### Flipper
- `floorplan_dashboard` — per-restaurant enable flag.

## Acceptance Criteria
1. `GET /restaurants/:id/floorplan` returns 200 for a manager/staff user and renders all table tiles.
2. A table with an active order in `ordered` status shows a blue "Ordered" chip.
3. A table with `ordr.status == 'billrequested'` shows a purple chip and a "Bill Requested" badge.
4. A table with no active order shows "Available" with a green indicator.
5. When an order status changes server-side, the corresponding table tile updates in the browser within 2 seconds without a full page reload (ActionCable + Turbo Stream).
6. Filtering by "Bill requested" hides all table tiles except those with `billrequested` status.
7. A table where the active order has been in `preparing` for more than 15 minutes shows the "Delayed" attention heuristic.
8. A non-staff user (customer session) cannot access the floorplan route (returns 403 or redirect).
9. The page loads in under 5 seconds for a restaurant with 30 tables.
10. Participant count is accurate and does not cause N+1 queries.

## Out of Scope
- Drag-and-drop custom table layout (post-launch).
- Staff actions from the tile (mark ready, mark delivered) — view-only for v1; actions in Phase 2.
- Multiple rooms or floors (single floor view in v1).
- Kitchen display integration from this view.

## Open Questions
1. What is the canonical "table" model for this feature? Confirm: `Tablesetting` is used as the table entity. If a separate `Table` model exists or is planned (see wait-time estimation spec), clarify the relationship.
2. Can there be multiple active orders per table simultaneously? If yes, what is the display rule? Recommended: surface the newest non-closed order and show a warning badge if multiple exist.
3. Should staff be able to perform actions (mark delivered, request bill) directly from the tile in v1, or is this view-only? Recommended: view-only for launch; actions in a subsequent release.
