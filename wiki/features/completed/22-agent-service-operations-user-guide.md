# Service Operations Agent — User Guide

**Feature**: #22 — Service Operations Agent
**Status**: Completed 2026-04-05
**Queue**: `agent_realtime` (high concurrency)
**Flipper flags**: `agent_framework` + `agent_service_operations`

---

## What this feature does

The Service Operations Agent monitors live kitchen and floor activity in real time and pushes advisory recommendation cards to your staff dashboards. It detects three types of situations:

1. **Kitchen congestion** — too many items in "preparing" state simultaneously
2. **Long-wait tables** — a table has been waiting longer than your configured threshold without any items reaching "preparing" state
3. **86 suggestions** — a menu item's stock has fallen to 2 or fewer

All recommendations are advisory. The agent never autonomously modifies any order, item, or customer record. Staff must confirm every action.

---

## Enabling the feature

In the Flipper admin UI (`/flipper`):

1. Enable `agent_framework` for the restaurant
2. Enable `agent_service_operations` for the restaurant

Once enabled, `KitchenHeartbeatJob` will begin emitting `kitchen.queue_check` events every minute for that restaurant (provided it has at least one active order).

---

## Configuration

Two per-restaurant settings can be adjusted via a migration or in the admin console:

| Setting | Column | Default | Description |
|---------|--------|---------|-------------|
| Long-wait threshold | `service_operations_wait_threshold_minutes` | 25 min | How long an order must be open before triggering a long-wait alert |
| Congestion threshold | `kitchen_congestion_threshold` | 8 items | Number of concurrent "preparing" items that triggers a congestion card |

To adjust for a specific restaurant:

```ruby
restaurant = Restaurant.find(123)
restaurant.update!(
  service_operations_wait_threshold_minutes: 20,
  kitchen_congestion_threshold: 6,
)
```

---

## How recommendations appear on dashboards

Recommendation cards are broadcast via ActionCable to three channels:

| Recommendation type | Channel | Stream |
|---------------------|---------|--------|
| Kitchen congestion | `KitchenChannel` | `kitchen_#{restaurant_id}` |
| 86 suggestion | `KitchenChannel` | `kitchen_#{restaurant_id}` |
| Long-wait alert | `UserChannel` | `user_#{manager_user_id}_channel` |
| Prep time estimate | `StationChannel` | `kitchen_#{restaurant_id}`, `bar_#{restaurant_id}` |

The ActionCable payload includes `action: 'agent_recommendation'` so Stimulus controllers on each dashboard can render a dismissable card.

---

## The 86 confirmation flow

When a low-stock item is detected:

1. An `AgentApproval` record (type: `item_86`, status: `pending`) is created.
2. A recommendation card appears on the kitchen dashboard with the item name and current stock.
3. Staff clicks **Confirm 86** on the card.
4. The browser sends `POST /restaurants/:id/agent_workbench/:run_id/approvals/:approval_id/confirm_86`.
5. The `AgentApproval` is moved to `approved` status.
6. `Agents::Tools::FlagItemUnavailable` sets `menuitem.hidden = true`.
7. The item is removed from the live SmartMenu immediately.

Staff clicks **Dismiss** instead:
- `DELETE /restaurants/:id/agent_workbench/:run_id/approvals/:approval_id/dismiss_recommendation`
- The `AgentApproval` is moved to `rejected` status.
- No item state change occurs.

---

## Safety guarantees

- The `FlagItemUnavailable` tool raises `Agents::UnauthorisedActionError` if called without a valid `AgentApproval` with status `approved`.
- Long-wait cards contain no action button that modifies any `Ordr` record — they are advisory text only.
- Congestion cards are advisory only — no state changes.
- If the `agent_realtime` Sidekiq queue is backed up (>30 pending jobs), a cached recommendation snapshot (5-minute TTL) is served rather than blocking dashboards.

---

## Monitoring and quality measurement

Every workflow run creates a lightweight `AgentWorkflowRun` record with 4 `AgentWorkflowStep` entries. These are visible in the AI Workbench at:

```
/restaurants/:id/agent_workbench
```

Filter by `workflow_type: 'service_operations'` to see only ops agent runs.

The `log_outcome` step records:
- `cards_pushed` — number of recommendation cards sent
- `approvals_created` — number of item_86 approvals created
- `fast_path_used` — whether the LLM was bypassed (it almost always should be)
- `recommendation_count` — total recommendations generated

Staff acceptance rate of 86 suggestions can be computed by querying:

```ruby
AgentApproval
  .joins(:agent_workflow_run)
  .where(agent_workflow_runs: { workflow_type: 'service_operations' }, action_type: 'item_86')
  .group(:status)
  .count
# => { "approved" => N, "rejected" => M, "pending" => P }
```

---

## Event triggers

The agent responds to three domain events:

| Event | Source | Frequency |
|-------|--------|-----------|
| `kitchen.queue_check` | `KitchenHeartbeatJob` | Every 60 seconds (restaurants with active orders only) |
| `inventory.low` | External emitter (see notes) | On demand |
| `order.submitted` | External emitter (see notes) | On new order |

Note: `inventory.low` and `order.submitted` events are registered in the Dispatcher but not yet emitted by the platform automatically. They can be published manually via `AgentDomainEvent.publish!` for testing, or wired to existing order/inventory callbacks in a follow-up.

---

## Architecture notes

- **Service**: `app/services/agents/workflows/service_operations_workflow.rb`
- **Job**: `app/jobs/agents/service_operations_workflow_job.rb` (queue: `agent_realtime`)
- **Heartbeat job**: `app/jobs/agents/kitchen_heartbeat_job.rb` (queue: `agent_realtime`, every 60s)
- **Tool**: `app/services/agents/tools/flag_item_unavailable.rb`
- **Safety error**: `app/services/agents/unauthorised_action_error.rb`
- **Migration**: `20260405100001_add_service_operations_settings_to_restaurants.rb`

---

## Out of scope (v1)

- Autonomous order cancellation, status changes, or refunds — manager-only, outside agent scope
- Integration with third-party inventory management systems
- Customer-facing wait time display (see Feature #13 — Table Wait Time Estimation)
- Shift scheduling or labour optimisation recommendations
