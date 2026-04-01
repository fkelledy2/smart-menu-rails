# Realtime Ordritem Tracking & Passive Customer Feedback

## Status
- Priority Rank: #34
- Category: Post-Launch
- Effort: L
- Dependencies: Existing `Ordritem` model, existing `OrdrChannel` (customer-facing), existing `KitchenChannel` / `StationChannel` (staff-facing), Sidekiq, ActionCable (Redis adapter)
- Refined: true

## Problem Statement
Customers currently have no visibility into the per-item progress of their order after placing it. The only feedback is the coarse-grained `Ordr` status. This creates "where is my order?" friction at the table — customers do not know whether their Guinness is being poured or their steak is still waiting to go on. Kitchen and bar staff, meanwhile, operate batch-first: they start all kitchen items at once and mark the bar ticket ready as a group. Any solution that forces staff into per-item workflows will be rejected on the floor.

This feature tracks fulfillment state at the `Ordritem` level and surfaces it passively to the customer in realtime, without requiring staff to change their existing batch workflows.

## Success Criteria
- Each `Ordritem` carries a `fulfillment_status` (`pending → preparing → ready → collected`) and a `station` (`kitchen` or `bar`) assignment
- Staff can advance all items at a station in a single tap (batch action); per-item override is available as a secondary interaction
- Customers see item-level status updates inline in their smartmenu order view, updating automatically via ActionCable — no toast, sound, vibration, or modal
- A derived order summary label (`Received / Preparing / Partially Ready / Ready / Complete`) is computed from item states and broadcast with each update
- All state transitions are recorded in `ordritem_events` for future analytics
- No cross-order data is accessible to a customer through the WebSocket subscription

## User Stories
- As a customer, I want to see each item in my order update passively (badge/label change) as the kitchen or bar processes it, so I know where things are without having to flag down staff.
- As a kitchen staff member, I want to tap "Start Kitchen" once and have all pending kitchen items move to preparing in a single action, so I don't lose time on per-item tapping.
- As a bar staff member, I want to tap "Bar Ready" once and have all preparing bar items move to ready, so service remains fast.
- As a restaurant manager, I want an audit trail of every item status transition stored in `ordritem_events`, so I can use timing data for future service analytics.
- As a platform admin, I want this feature gated behind a Flipper flag so I can roll it out per-restaurant during a controlled beta.

## Functional Requirements

### Ordritem Fulfillment Status
1. `Ordritem` gains a `fulfillment_status` column (integer enum, separate from the existing `status` column which tracks the item's lifecycle from `opened` through `paid`). Values: `pending: 0, preparing: 1, ready: 2, collected: 3`. Default: `pending`.
2. Allowed transitions are strictly enforced: `pending → preparing`, `preparing → ready`, `ready → collected`. Any other transition is rejected with an error.
3. `Ordritem` gains a `station` column (integer enum): `kitchen: 0, bar: 1`. This is set at order placement time based on the associated `Menuitem`'s station configuration. The `station` value is immutable after creation.

### Fulfillment Timestamps
4. Three timestamp columns are added to `ordritems`: `preparing_at`, `ready_at`, `collected_at`. Each is set to the current UTC time when the corresponding transition occurs. `fulfillment_status_changed_at` records the most recent transition time for query convenience.

### Group Transitions (Batch-First Staff Workflow)
5. `Ordritems::TransitionGroup` selects all `Ordritem` records for a given `ordr_id` and `station` that are in a specific `fulfillment_status`, and advances each via `Ordritems::TransitionStatus`. Example: "Start kitchen" = all `kitchen` items in `pending` → `preparing`.
6. The batch action returns a summary: `{ station:, from_status:, to_status:, transitioned_count:, skipped_count: }`.
7. Per-item override is available via `Ordritems::TransitionStatus` called on a single record. This is used only when a specific item needs to be corrected independently of the batch.

### Customer Realtime Updates
8. Every successful transition triggers `Ordritems::BroadcastStatusChangeJob` (enqueued after DB commit via `after_commit` callback on `OrdritemEvent` creation).
9. The job broadcasts to the existing `OrdrChannel` stream `ordr_#{ordr_id}_channel`. No new channel is created — this extends the existing customer subscription surface.
10. The broadcast payload uses event type `order_item_status_changed` and includes the derived order summary label (computed from all `Ordritem#fulfillment_status` values for the order at broadcast time).

### Customer UI
11. The customer smartmenu order view updates inline on receiving the broadcast — badge change, status label update, optional "Updated just now" timestamp.
12. No toast, modal, sound, vibration, or push notification is shown to the customer.
13. On reconnect, the customer UI re-fetches current state from the server (Turbo Frame reload or HTTP request) to reconcile any missed broadcasts.
14. The derived order summary is: all `pending` → "Received"; any `preparing` → "Preparing"; mixed `ready` and non-`collected` → "Partially Ready"; all `ready` → "Ready"; all `collected` → "Complete".

### Event Audit Log
15. Every `fulfillment_status` transition creates an `OrdritemEvent` record in the `ordritem_events` table with full before/after state, actor, and metadata.
16. `ordritem_events` records are immutable — no updates or deletes.

## Non-Functional Requirements
- Broadcast enqueued only after DB commit (`after_commit` on `OrdritemEvent`) — no phantom updates from rolled-back transitions.
- `Ordritems::TransitionStatus` is idempotent: transitioning an item already in the target state is a no-op (returns the item without error), not a new event.
- Customer WebSocket subscriptions are authorised: `OrdrChannel` must verify that the subscribing session holds the token for the specific `Ordr` before streaming. See Security section.
- All writes go through the `Ordritems::TransitionStatus` service — no direct `update_column` calls to `fulfillment_status` outside the service.
- New indexes must not degrade primary write performance. The `ordritem_events` table is append-only and will grow with order volume — partition strategy should be considered once table exceeds 10M rows (post-launch concern, not v1).
- Statement timeout compliance: all queries on the primary database must complete within 5s; analytical queries on `ordritem_events` must use the read replica and complete within 15s.

## Technical Notes

### Critical: fulfillment_status is a new column, not a replacement for status
The existing `ordritems.status` column tracks the item's commercial lifecycle (`opened: 0, removed: 10, ordered: 20, preparing: 22, ready: 24, delivered: 25, billrequested: 30, paid: 35, closed: 40`). This column must not be changed. The new `fulfillment_status` column tracks kitchen/bar fulfillment state independently. Both enums coexist. The existing `preparing` and `ready` values in the `status` enum are legacy — they may be rationalised in a future migration pass but that is out of scope here.

### Migration: Ordritem additions
```ruby
add_column :ordritems, :fulfillment_status, :integer, null: false, default: 0
add_column :ordritems, :station, :integer
add_column :ordritems, :fulfillment_status_changed_at, :datetime
add_column :ordritems, :preparing_at, :datetime
add_column :ordritems, :ready_at, :datetime
add_column :ordritems, :collected_at, :datetime
add_index  :ordritems, [:ordr_id, :fulfillment_status], name: 'index_ordritems_on_ordr_fulfillment_status'
add_index  :ordritems, [:ordr_id, :station, :fulfillment_status], name: 'index_ordritems_on_ordr_station_fulfillment'
```

### Migration: New ordritem_events table
```ruby
create_table :ordritem_events do |t|
  t.bigint   :ordritem_id, null: false
  t.bigint   :ordr_id, null: false
  t.bigint   :restaurant_id, null: false
  t.string   :event_type, null: false
  t.integer  :from_status
  t.integer  :to_status
  t.datetime :occurred_at, null: false
  t.string   :actor_type
  t.bigint   :actor_id
  t.jsonb    :metadata, default: {}
  t.timestamps
end

add_index :ordritem_events, :ordritem_id
add_index :ordritem_events, :ordr_id
add_index :ordritem_events, :restaurant_id
add_index :ordritem_events, :occurred_at
add_index :ordritem_events, [:ordr_id, :occurred_at]
add_foreign_key :ordritem_events, :ordritems
add_foreign_key :ordritem_events, :restaurants
```

### Model: Ordritem additions
```ruby
enum :fulfillment_status, { pending: 0, preparing: 1, ready: 2, collected: 3 }, prefix: :fulfillment
enum :station, { kitchen: 0, bar: 1 }, prefix: :station

after_commit :enqueue_broadcast_on_fulfillment_change, on: :update, if: :saved_change_to_fulfillment_status?
```

The `prefix:` option prevents conflicts with the existing `status` enum helpers.

### Model: OrdritemEvent
```ruby
class OrdritemEvent < ApplicationRecord
  belongs_to :ordritem
  belongs_to :restaurant

  validates :event_type, :occurred_at, presence: true
  validates :to_status, presence: true

  # Immutable — no updates or destroys
  before_update { throw :abort }
  before_destroy { throw :abort }
end
```

### Service: Ordritems::TransitionStatus
Location: `app/services/ordritems/transition_status.rb`

Responsibilities:
- Validate the requested transition is permitted (`ALLOWED_TRANSITIONS` constant)
- Update `fulfillment_status`, the relevant timestamp (`preparing_at`, `ready_at`, or `collected_at`), and `fulfillment_status_changed_at` in a single transaction
- Create an `OrdritemEvent` record (actor polymorphic — `User` for staff-initiated, `nil` for system-initiated)
- Return `{ success: true, ordritem: }` or `{ success: false, error: }`
- Idempotent: if the item is already in `to_status`, return `{ success: true, ordritem:, noop: true }` without creating a new event

```ruby
ALLOWED_TRANSITIONS = {
  'pending'   => 'preparing',
  'preparing' => 'ready',
  'ready'     => 'collected',
}.freeze
```

### Service: Ordritems::TransitionGroup
Location: `app/services/ordritems/transition_group.rb`

Responsibilities:
- Accept `ordr_id:`, `station:`, `from_status:`, `to_status:`, `actor:`
- Scope `Ordritem.where(ordr_id:, station:, fulfillment_status: from_status)` — tenant-safe via `ordr_id`
- Apply `Ordritems::TransitionStatus` to each item
- Return `{ station:, from_status:, to_status:, transitioned_count:, skipped_count:, errors: [] }`

### Job: Ordritems::BroadcastStatusChangeJob
Location: `app/jobs/ordritems/broadcast_status_change_job.rb`
Queue: `:default`
Trigger: enqueued by `OrdritemEvent#after_create_commit`

Responsibilities:
- Load `Ordritem` and its `Ordr` (with restaurant)
- Compute derived order summary from all `fulfillment_status` values on the `Ordr`
- Build payload (see Broadcast Payload below)
- `ActionCable.server.broadcast("ordr_#{ordr_id}_channel", payload)`

This extends the existing `OrdrChannel` stream — no new channel required.

### Broadcast Payload
```json
{
  "type": "order_item_status_changed",
  "ordr_id": "123",
  "ordritem_id": "456",
  "item_name": "Guinness",
  "quantity": 2,
  "station": "bar",
  "from_status": "pending",
  "to_status": "preparing",
  "customer_status_label": "Preparing",
  "occurred_at": "2026-04-01T14:32:00Z",
  "order_summary": {
    "status": "preparing",
    "label": "Preparing"
  }
}
```

`customer_status_label` and `order_summary.label` are localisation-safe strings computed server-side; the Stimulus controller does not derive labels from raw status strings.

### Staff-Facing Channel Integration
`KitchenChannel` and `StationChannel` already handle inbound `update_status` messages from staff clients. Batch group transitions are wired into these channels by adding a new `action` handler:

```ruby
# In KitchenChannel#receive:
when 'advance_station'
  handle_station_advance(data)
```

`handle_station_advance` calls `Ordritems::TransitionGroup` after verifying restaurant membership. Existing `handle_status_update` (for `Ordr`-level status) is unchanged.

### Customer-Facing Stimulus Controller
`app/javascript/controllers/ordritem_tracking_controller.js`

Responsibilities:
- Connect to `OrdrChannel` on mount (reuse existing subscription if already open on the page)
- Listen for `order_item_status_changed` events
- Update the target `[data-ordritem-id]` element's badge, label, and timestamp
- Update the order summary label
- On reconnect, trigger a Turbo Frame reload of the order status partial

### Pundit Policy
`OrdritemPolicy` already exists. Add:
- `transition_fulfillment_status?` — authenticated staff (`manager` or `admin` employee role) for the item's restaurant
- Customer-facing transitions (e.g. `collected`) initiated by the customer via UI — scope to the `DiningSession` token, not a `User`. Validate in the service, not the policy, since `DiningSession` holders are not `User` objects.

### Flipper Flag
`ordritem_realtime_tracking` — gates the new `fulfillment_status` UI on the customer smartmenu view, the batch action buttons on the kitchen/bar staff dashboards, and the `OrdritemEvent` creation in `Ordritems::TransitionStatus`. The migration runs unconditionally (safe — new nullable columns); the feature flag controls activation only.

### No new gems required
All required capabilities are covered by the existing stack: ActiveRecord enums, ActionCable, Sidekiq, Pundit, and Hotwire Turbo + Stimulus.

## Acceptance Criteria
1. An `Ordritem` in `fulfillment_status: :pending` transitions to `:preparing` via `Ordritems::TransitionStatus`; an `OrdritemEvent` is created; `preparing_at` is set; `Ordritems::BroadcastStatusChangeJob` is enqueued after commit.
2. Attempting `pending → ready` (skipping `preparing`) is rejected by `Ordritems::TransitionStatus` with `{ success: false, error: 'Invalid transition' }`.
3. `Ordritems::TransitionGroup` called with `station: :kitchen, from_status: :pending, to_status: :preparing` advances all matching items in one call; items already in `preparing` are counted as skipped, not errored.
4. A customer subscribed to `OrdrChannel` for their `Ordr` receives the broadcast payload within 2 seconds of the transition commit.
5. The customer smartmenu order view updates the relevant item badge and label without a page reload; no toast or modal appears.
6. A customer attempting to subscribe to `ordr_#{other_ordr_id}_channel` for an order that does not belong to their `DiningSession` token is rejected by the channel.
7. The `ordritem_realtime_tracking` Flipper flag, when disabled, hides all new UI elements; existing `Ordr`-level status behaviour is unchanged.
8. Two rapid calls to `Ordritems::TransitionStatus` with the same `to_status` produce exactly one `OrdritemEvent` (idempotent).
9. All derived order summary labels are correctly computed: a 3-item order with one `ready` kitchen item and two `pending` bar items returns `"Preparing"` (any preparing/ready-partial → "Partially Ready" or "Preparing" per derivation logic).
10. The `ordritem_events` table contains a full audit trail after a complete order lifecycle (`pending → preparing → ready → collected`) for all items.

## Implementation Checklist

### Phase 1 — Foundation
- [ ] Migration: add `fulfillment_status`, `station`, `fulfillment_status_changed_at`, `preparing_at`, `ready_at`, `collected_at` to `ordritems`
- [ ] Migration: create `ordritem_events` table with indexes
- [ ] `Ordritem` enum declarations (`fulfillment_status`, `station`) with `prefix:` to avoid collision with existing `status` enum
- [ ] `OrdritemEvent` model with immutability guards
- [ ] `OrdritemPolicy` — add `transition_fulfillment_status?`
- [ ] `Ordritems::TransitionStatus` service — transition validation, timestamp writes, event creation
- [ ] `Ordritems::TransitionGroup` service — batch scoping, delegates to `TransitionStatus`
- [ ] Flipper flag `ordritem_realtime_tracking` registered

### Phase 2 — Staff UX
- [ ] `Ordritems::BroadcastStatusChangeJob` — ActionCable broadcast to `ordr_#{id}_channel`
- [ ] `after_create_commit` on `OrdritemEvent` enqueues broadcast job
- [ ] `KitchenChannel#receive` — add `advance_station` handler calling `Ordritems::TransitionGroup`
- [ ] `StationChannel` — add equivalent `advance_station` handler
- [ ] Kitchen/bar dashboard: batch action buttons ("Start Kitchen", "Bar Ready") wired to `advance_station` via ActionCable send
- [ ] Per-item override UI in dashboard (secondary, expandable)
- [ ] Flipper flag gates new dashboard UI elements

### Phase 3 — Customer UX
- [ ] `ordritem_tracking_controller.js` Stimulus controller — receives `order_item_status_changed` events, updates DOM
- [ ] Customer smartmenu order view partial updated with `data-ordritem-id` targets and status badge markup
- [ ] Derived order summary label displayed in order header
- [ ] Reconnect handler — Turbo Frame reload of order status partial on `OrdrChannel` reconnect
- [ ] `OrdrChannel` subscription guard — verify `DiningSession` token ownership before streaming
- [ ] Flipper flag gates customer-facing status UI

### Phase 4 — Hardening
- [ ] Model specs: `test/models/ordritem_event_test.rb` — immutability, validations
- [ ] Service specs: `test/services/ordritems/transition_status_test.rb` — allowed transitions, invalid transitions, idempotency, timestamp writes, event creation
- [ ] Service specs: `test/services/ordritems/transition_group_test.rb` — batch scoping, skipped items, error handling
- [ ] Job specs: `test/jobs/ordritems/broadcast_status_change_job_test.rb` — payload shape, correct channel
- [ ] Request/controller specs: channel auth — cross-order subscription rejected
- [ ] System test: `test/system/ordritem_realtime_tracking_test.rb` — end-to-end transition + broadcast + DOM update
- [ ] Edge cases covered: mixed station states, duplicate transition calls, reconnect reconciliation
- [ ] `bin/fast_test` — all passing
- [ ] `bundle exec rubocop` — clean
- [ ] `bundle exec brakeman` — clean
- [ ] `yarn lint` — clean
- [ ] Flipper flag rollout plan: enable per-restaurant in beta before platform-wide

## Out of Scope (v1)
- ETA or wait time prediction per item
- Push notifications (SMS, APNs, FCM) for item readiness
- Runner/service assignment workflows (who carries the dish)
- ML-based optimisation of station workflow sequencing
- Delay explanations or reason codes on item status
- Partition strategy for `ordritem_events` (review when table exceeds 10M rows)
- `actual_weight` recording for weight-based items (see Weight-Based Pricing spec)
- Customer-initiated `collected` transition — v1 marks collected by staff only

## Open Questions

~~1. Should the `station` assignment on `Ordritem` be configured at the `Menuitem` level or set manually per item?~~
**Resolved:** Station is set at the `Menuitem` and `Menusection` level. Food items route to `kitchen`; drinks route to `bar`. The Phase 1 migration must add `default_station` (integer enum: `kitchen: 0, bar: 1`) to both `menuitems` and `menusections` so that `station` on `Ordritem` is seeded from the menu item's setting at order creation time. A back-office toggle per menu item / section is required in the menu edit UI.

~~2. The `OrdrChannel` subscription was unguarded — a latent security risk.~~
**Resolved and shipped:** `OrdrChannel` now rejects unauthenticated subscriptions when the `qr_security_v1` flag is enabled. The fix verifies that the subscriber's `DiningSession` token matches the `restaurant_id` + `tablesetting_id` of the requested order (for `order_id` subscriptions) or the smartmenu slug (for slug subscriptions). Staff with `current_user` are always permitted. When `qr_security_v1` is disabled, the legacy open-access behaviour is preserved. Changes shipped: `app/channels/application_cable/connection.rb`, `app/channels/ordr_channel.rb`, `test/channels/ordr_channel_test.rb` (9 tests).
3. What is the localisation strategy for `customer_status_label` and `order_summary.label`? The platform already supports 40+ languages via DeepL for menu content. If these labels must be translated per-customer locale, the broadcast job needs the customer's locale. Recommend server-side I18n keys in `config/locales/en/` with DeepL coverage as a Phase 4 follow-up.
4. Should `OrdritemEvent` records be replicated to the read replica for analytical queries, or is the primary sufficient for v1 query volumes? Recommend replica for any `GROUP BY occurred_at` reporting queries given expected append volume at scale.
5. The existing `status` enum on `Ordritem` has `preparing: 22` and `ready: 24` — values that semantically overlap with the new `fulfillment_status` enum. A future migration pass should rationalise these (likely removing `preparing` and `ready` from the legacy `status` enum and routing through `fulfillment_status`). Flag this as a known tech-debt item for post-v1 cleanup.
