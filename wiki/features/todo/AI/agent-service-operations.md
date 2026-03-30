# Service Operations Agent

## Status
- Priority Rank: #22 (Phase 2 agent — requires live order volume to be meaningful; highest latency sensitivity of all agents)
- Category: Post-Launch — agent tier, Phase 2
- Effort: M
- Dependencies: Agent Framework (#17), Kitchen/Station dashboard (existing), `OrdrChannel` ActionCable (existing), `KitchenChannel` (existing), OpenAI API

## Problem Statement
During peak service, kitchen and floor staff are overwhelmed with concurrent demands and have no automated system to detect brewing problems before they escalate. A rising queue of prep-heavy dishes, a bar order surge, an item running out of stock, or a table that has been waiting unusually long — these are all detectable signals that currently require a manager to notice manually. By the time they are noticed, the damage to service quality is often already done. The Service Operations Agent monitors live order flow events and surfaces targeted, real-time operational recommendations to staff in the right dashboard at the right moment — reducing congestion, protecting the customer experience, and giving managers early warning on service recovery situations.

This agent has the strictest safety constraints of the agent tier: it must never autonomously modify order state, cancel orders, issue refunds, or 86 items without explicit staff confirmation. It is a **recommendation surface**, not an autonomous actor.

## Success Criteria
- Kitchen staff receive "86 this item" suggestions within 30 seconds of a stock-pressure signal being detected.
- Manager long-wait alerts are surfaced within 60 seconds of a table exceeding the wait threshold.
- Kitchen staff acceptance rate of "86" suggestions exceeds 70% (measures recommendation quality, not just volume).
- The agent's recommendations never autonomously modify any `Ordr`, `Ordritem`, or `Menuitem` record — all mutations require explicit staff confirmation.
- The agent degrades gracefully under queue backlog: cached recommendations are surfaced rather than blocking staff dashboards.

## User Stories
- As a kitchen team member, I want to see a suggestion to 86 an item when stock is running low, so I can act before we disappoint a customer.
- As a floor manager, I want an alert when a table has been waiting unusually long, with a suggested recovery action, so I can intervene before the customer complains.
- As a bar team member, I want reorder suggestions during a cocktail surge, so high-margin drinks are surfaced prominently when they are selling fast.
- As a manager, I want to be confident that the agent is never taking autonomous actions on orders or availability — I need to confirm everything before it happens.

## Functional Requirements

1. The agent is triggered by four domain events: `order.submitted`, `order_item.preparing`, `inventory.low`, and a periodic kitchen heartbeat (`kitchen.queue_check`) emitted every 60 seconds by `KitchenHeartbeatJob`.
2. `Agents::Dispatcher` maps these events to `Agents::ServiceOperationsWorkflowJob` on the `agent_realtime` Sidekiq queue. The `agent_realtime` queue must have a high concurrency setting to handle burst events during peak service.
3. The workflow is kept deliberately short — maximum 4 steps to meet the latency requirement:
   - **Step 1: queue_assess** — read current `Ordr` queue state: active orders, items in each status (pending / preparing / ready), order timestamps, table assignments. Read from primary DB (replica latency is unacceptable here — stale data produces bad recommendations). Estimate queue depth and flag congestion if preparing-count > configurable threshold (default: 8 concurrent preparing items).
   - **Step 2: congestion_reason** — OpenAI Responses API call (or rule-based decision for simple cases — see notes). Input: queue snapshot, item prep times, stock signals. Output: one of three action types: `staff_alert` (push recommendation to dashboard), `item_flag` (suggest 86'ing an item), `recovery_trigger` (flag long-wait table to manager).
   - **Step 3: staff_alert** — push the recommendation to the relevant dashboard via ActionCable. Kitchen congestion → `KitchenChannel`. Bar surge → `StationChannel`. Long-wait → `UserChannel` (manager). The recommendation is advisory text + a confirm button — no state change occurs until staff confirms.
   - **Step 4: log_outcome** — write a lightweight `AgentWorkflowRun` record with the recommendation type, target, and whether staff confirmed or dismissed it. Used for quality measurement.
4. **Congestion detection**: if preparing-order count > threshold, the agent suggests slowing the promotion of prep-heavy items (e.g. "Consider pausing new orders for Rack of Lamb — 12 currently in prep"). This is surfaced as a dashboard card with a "Pause item" confirmation button.
5. **"86 this item" flow**: detected via `inventory.low` event or stock pressure inference. The agent surfaces an `AgentApproval` (type: `item_86`) to the kitchen dashboard as a card with "Confirm 86" / "Dismiss" buttons. Staff confirmation calls `flag_item_unavailable` tool which updates `Menuitem#available: false`. The agent never calls `flag_item_unavailable` autonomously.
6. **Long-wait detection**: any table with an open order older than the restaurant's configurable wait threshold (default: 25 minutes from `order.submitted` without an `order_item.preparing` event) triggers a `recovery_trigger` recommendation pushed to the manager dashboard. The recommendation is a text card: order summary, items ordered, time elapsed, and a suggested action ("Visit table", "Send apology message"). No autonomous action.
7. **Prep time estimates**: during congestion, the agent computes an estimated wait time from queue depth and average item prep times. This is pushed to the `StationChannel` for display at kitchen stations.
8. All agent recommendations on dashboards are rendered as dismissable cards. Dismissed recommendations are logged. Confirmed recommendations trigger the associated action (via staff interaction, not autonomously).
9. **Degradation behaviour**: if the `agent_realtime` Sidekiq queue is backed up (>30 pending jobs), the agent reads from a cached recommendation snapshot (updated every 5 minutes) rather than computing a fresh recommendation, ensuring dashboard cards are always populated but never block.
10. The agent must never recommend an action that modifies an `Ordr` record — order cancellations, status changes, and refunds are exclusively staff-initiated actions outside the agent's scope.

## Non-Functional Requirements
- End-to-end latency from event emission to dashboard card display: under 30 seconds for `inventory.low` and `kitchen.queue_check` events.
- The reasoning step (Step 2) should prefer a rule-based fast path for simple congestion signals (queue depth thresholds are deterministic — no LLM needed). Reserve LLM calls for ambiguous or multi-signal situations only. This reduces latency and API cost.
- The `agent_realtime` queue worker must not be starved by lower-priority agent queues. Sidekiq queue weight configuration must enforce this.
- Step 1 reads from the primary DB (not replica) — stale queue state is worse than a small latency increase.
- No `AgentApproval` record should block the dashboard render — approvals are surfaced as overlay cards, not as page-blocking modals.
- Flipper flag `agent_service_operations` must be enabled per restaurant.

## Technical Notes

### New Services
- `agents/workflows/service_operations_workflow.rb`

### New Jobs
- `agents/service_operations_workflow_job.rb` — `agent_realtime` queue
- `agents/kitchen_heartbeat_job.rb` — runs every 60 seconds via Sidekiq cron; emits `kitchen.queue_check` domain event for restaurants with the flag enabled and at least one active order

### ActionCable Integration
- Push recommendations to dashboards using existing channels:
  - `KitchenChannel` — kitchen congestion + 86 suggestion cards
  - `StationChannel` — prep time estimates and bar surge cards
  - `UserChannel` — manager long-wait alerts
- New Turbo Stream broadcast action: `agent_recommendation` — renders a dismissable card partial into the dashboard's agent recommendations region
- Add a `#dismiss_recommendation(approval_id)` action to the relevant Stimulus controllers on each dashboard

### Rule-Based Fast Path (Step 2 optimisation)
For the following signals, skip the LLM and use deterministic rules:
- `queue_depth > threshold` → always surface congestion card (no LLM needed)
- `inventory.low` event with `quantity <= 2` → always surface 86 suggestion (no LLM needed)
- `order_age > wait_threshold` → always surface long-wait card (no LLM needed)
Reserve LLM for: multi-signal combinations, bar surge pattern detection, and contextual recovery message drafting.

### `flag_item_unavailable` Tool Safety
- This tool must not be callable without a `confirmed: true` parameter set by staff interaction.
- The tool checks for an associated `AgentApproval` with status `approved` before executing.
- If called without a valid approval, it raises `Agents::UnauthorisedActionError` and logs the attempt.

### New Restaurant Setting
- `restaurants.service_operations_wait_threshold_minutes` (integer, default: 25) — configurable per restaurant
- `restaurants.kitchen_congestion_threshold` (integer, default: 8) — configurable per restaurant
- Add these columns to the `restaurants` table migration

### Caching
- Cache key: `service_ops:#{restaurant_id}:recommendation_snapshot` — Redis, 5-minute TTL
- Updated after each successful Step 3 completion
- Served from cache when `agent_realtime` queue is congested

### Flipper Flags
- `agent_framework` (required)
- `agent_service_operations`

## Acceptance Criteria
1. An `inventory.low` event with `quantity <= 2` results in an `AgentApproval` record (type: `item_86`, status: `pending`) and a recommendation card on the kitchen dashboard within 30 seconds, without any LLM call (rule-based fast path).
2. Kitchen staff clicking "Confirm 86" on the card triggers `flag_item_unavailable` tool, which calls the appropriate service to set `Menuitem#available: false`. The item immediately disappears from the live SmartMenu.
3. Kitchen staff clicking "Dismiss" marks the `AgentApproval` as `dismissed` and removes the card. No item availability change occurs.
4. An `Ordr` record that has been open for longer than `service_operations_wait_threshold_minutes` without any `order_item.preparing` event triggers a long-wait card on the manager dashboard via `UserChannel`.
5. The long-wait card shows: table number, order summary, elapsed time, and a suggested action. It does not contain a button that modifies any `Ordr` record.
6. The `flag_item_unavailable` tool raises `Agents::UnauthorisedActionError` if called without a confirmed `AgentApproval` record — verified by a unit test on the tool.
7. When the `agent_realtime` queue has > 30 pending jobs, the dashboard renders recommendations from the cached snapshot rather than timing out.
8. `KitchenHeartbeatJob` runs every 60 seconds and emits exactly one `kitchen.queue_check` event per restaurant with the flag enabled that has at least one active order — not for idle restaurants.
9. All `AgentWorkflowRun` records for the `service_operations` workflow type are lightweight (≤ 4 steps) — no run creates more than 4 `AgentWorkflowStep` records.
10. With `agent_service_operations` flag disabled, no recommendations are pushed to any dashboard, and `KitchenHeartbeatJob` does not emit events for that restaurant.

## Out of Scope
- Autonomous order cancellation or status mutation — never in scope for this agent.
- Autonomous refund or compensation issuance — manager only.
- Integration with third-party inventory management systems (in-app stock signal only in v1).
- Customer-facing wait time display (see Table Wait Time Estimation spec #12 — that is a separate feature).
- Shift scheduling or labour optimisation recommendations.

## Open Questions
1. Does `Menuitem` have an `available` boolean field currently? If not, confirm the correct field/method for 86'ing an item — this affects the `flag_item_unavailable` tool implementation.
2. What is the right threshold for "low inventory" signals? The current spec assumes `inventory.low` events are emitted by an existing inventory system — confirm whether that system exists or whether this agent must infer stock pressure from order velocity alone.
3. Should congestion recommendations be pushed to the kitchen dashboard as non-blocking overlay cards, or as a persistent status indicator? The current spec assumes overlay cards — but this needs UX validation with kitchen staff during early trials.
4. Is there a separate bar/beverages station concept, or is the `StationChannel` / station dashboard already handling this? Confirm the station model before building bar-surge targeting.
