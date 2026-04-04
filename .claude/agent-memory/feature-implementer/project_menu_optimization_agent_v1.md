---
name: Menu Optimization Agent v1 implementation decisions
description: Menu Optimization Agent #21 — change set workflow, approval routing, apply job, idempotency key, and gotchas (April 2026)
type: project
---

Menu Optimization Agent #21 shipped 2026-04-04.

**Why:** Provides restaurant owners concrete, actionable menu change proposals (not just advisory text) based on 7-day order performance data. Changes require manager approval before being applied to live menu.

**Architecture decisions:**
- 5-step workflow: read_performance → optimisation_reason → policy_validate → write_change_set → notify_manager
- `price_suggestion` action type is advisory-only — enforced by never creating `AgentApproval` records for it
- `image_queue` actions are auto-approved and immediately enqueue `MenuItemImageGeneratorJob`
- `section_reorder`, `item_rename`, `item_suppress`, `item_feature` → `require_approval`
- Idempotency: SHA256 key on `agent_approvals` (restaurant_id + analysis_week + action_type + target_id)
- 14-day cooldown on rejected actions (checked via `AgentApproval` table query)
- Scheduled rollout: `AgentArtifact#scheduled_apply_at` picked up by `ApplyApprovedMenuChangesJob` every 30 min

**Gotchas:**
- Menuitem uses `has_one :genimage` (singular), NOT `has_many :genimages` — check before using includes
- Genimage must be created with `restaurant_id:` in addition to `menuitem:` (not-null constraint)
- `unless/elsif` pattern in ERB views causes Brakeman parser error — always use `if/elsif` instead
- `return` inside `each_with_index` triggers RuboCop `Lint/NonLocalExitFromIterator` — use a `halted` flag + `break` instead
- `assert_no_difference` expects a numeric expression, not a string attribute like `status` — use `assert_equal` after the block instead

**Flipper flags:**
- `agent_framework` (required for all agents)
- `agent_menu_optimization` (this agent)

**Heroku Scheduler jobs to add:**
- `bundle exec rails runner "Agents::EmitMenuOptimizationEventsJob.perform_later"` — nightly at 02:00 UTC
- `bundle exec rails runner "Agents::ApplyApprovedMenuChangesJob.perform_later"` — every 30 minutes

**Routes added:**
- `GET /restaurants/:id/agent_workbench/optimization` — list change sets
- `POST /restaurants/:id/agent_workbench/run_optimization` — on-demand trigger
- `GET /restaurants/:id/agent_workbench/:id/optimization_review` — per-run review UI
- `PATCH /restaurants/:id/agent_workbench/:id/schedule_optimization` — set rollout time

**How to apply:** Ensure both Flipper flags enabled and >= 14 days of order history before expecting nightly runs to trigger.
