---
name: Service Operations Agent v1
description: Service Operations Agent v1 (#22): 4-step workflow, heartbeat job, flag_item_unavailable tool, UnauthorisedActionError safety guard, restaurant settings migration (April 2026)
type: project
---

Service Operations Agent v1 (#22) shipped 2026-04-05.

**Why:** Real-time kitchen ops intelligence — congestion detection, 86 suggestions, long-wait alerts. Strictest safety constraints of all agents: never modifies orders/items autonomously.

**Architecture:**
- `Agents::Workflows::ServiceOperationsWorkflow` — 4-step pipeline (queue_assess, congestion_reason, staff_alert, log_outcome)
- `Agents::ServiceOperationsWorkflowJob` — queue: `agent_realtime`
- `Agents::KitchenHeartbeatJob` — every 60s via Sidekiq cron, emits `kitchen.queue_check` for restaurants with active orders
- `Agents::Tools::FlagItemUnavailable` — hides `Menuitem#hidden = true` after staff confirms via AgentApproval
- `Agents::UnauthorisedActionError` — in `app/services/agents/unauthorised_action_error.rb`; raised if tool called without approved AgentApproval
- Migration `20260405100001` — adds `service_operations_wait_threshold_minutes` (default: 25) and `kitchen_congestion_threshold` (default: 8) to restaurants

**Flipper flags:** `agent_framework` + `agent_service_operations` (both must be enabled per restaurant)

**Key gotchas:**
- Menuitem "86" uses `hidden: true`, NOT an `available` boolean — Menuitem has no `available` column
- Menuitems don't have a `restaurant_id` column — must join via `menusections → menus → restaurants`
- `Inventory` has `currentinventory` (integer) and `status` enum — filter by `status: :active`
- `AgentApproval` column is `proposed_payload` (not `proposed_changes`)
- Dispatcher idempotency_key per heartbeat uses strftime('%Y%m%d%H%M') — one event per minute per restaurant
- `agent_realtime` Sidekiq queue already exists at weight 8 in sidekiq.yml — no config change needed
- `order.submitted` and `inventory.low` events are registered in Dispatcher but not yet auto-emitted by platform — wiring to model callbacks is a follow-up task

**Controller actions added to AgentWorkbenchController:**
- `POST .../approvals/:id/confirm_86` — approves AgentApproval then calls FlagItemUnavailable
- `DELETE .../approvals/:id/dismiss_recommendation` — rejects AgentApproval (no state change)

**How to apply:** When building agents that interact with kitchen/ops data, remember the menuitems→restaurant join pattern and the hidden flag convention.
