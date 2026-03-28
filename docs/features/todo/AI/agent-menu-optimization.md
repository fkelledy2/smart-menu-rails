# Menu Optimization Agent

## Status
- Priority Rank: #21 (Phase 2 agent — builds on Growth Digest patterns; requires order history depth)
- Category: Post-Launch — agent tier, Phase 2
- Effort: M
- Dependencies: Agent Framework (#17), Restaurant Growth Agent (#19) patterns, `ProfitMarginAnalyticsService` (exists), `AnalyticsService` (exists), `MenuOptimization` service/model (confirm existence), OpenAI API

## Problem Statement
Restaurant menus are largely static between deliberate updates. The arrangement of sections, prominence of items, description quality, and item availability do not automatically adapt to what is actually selling, what has high margin, or what the kitchen is currently capable of delivering. Owners make these changes manually and infrequently — usually only after a noticeable problem. The Menu Optimization Agent performs a regular, data-driven analysis of the restaurant's menu performance and generates a concrete set of proposed changes — not just observations — that the manager can approve and apply in a single session. The key distinction from the Growth Digest (#17) is that this agent produces a structured **change set** (reorder, rename, suppress, feature, image-generate) that is applied to the live menu through the standard approval workflow, rather than just advisory text the owner must act on manually.

## Success Criteria
- The agent produces a concrete, structured change set for the restaurant's menu at least weekly.
- The manager approval rate for proposed changes exceeds 60% (indicates the agent's recommendations are trusted).
- At least one measurable conversion or revenue metric improves within 4 weeks of a restaurant adopting the agent (tracked via before/after comparison).
- No price changes are ever applied to the live menu autonomously — all pricing suggestions are displayed as advisory text only, never as executable change actions.

## User Stories
- As a restaurant owner, I want the platform to automatically suggest specific menu improvements based on my sales data, so I don't have to be a data analyst to optimise my menu.
- As a restaurant manager, I want to review proposed menu changes and approve or reject them before they go live, so I retain full control over what my customers see.
- As a restaurant owner, I want the agent to flag slow-moving items with a suggested action (remove, reprice, or reimage) so I can make better stocking decisions.
- As a restaurant owner, I want high-margin items to be automatically surfaced for promotion rather than buried in a long list.

## Functional Requirements

1. The agent is triggered by the `menu_optimization.scheduled` domain event. `EmitMenuOptimizationEventsJob` (Heroku Scheduler, nightly at 02:00 UTC) writes one event per eligible restaurant (has `agent_menu_optimization` flag enabled, has >= 14 days of order data).
2. An on-demand trigger is available from the restaurant back office — "Run menu analysis now" button emits `menu_optimization.requested` domain event.
3. `Agents::Dispatcher` maps both events to `Agents::MenuOptimizationWorkflowJob` on the `agent_default` queue.
4. The workflow pipeline:
   - **Step 1: read_performance** — pull 7-day item metrics from `ProfitMarginAnalyticsService` and `AnalyticsService` on the replica DB. Tag items as: high_margin / low_margin, high_visibility / low_visibility, high_conversion / low_conversion, slow_mover / fast_mover, no_image. Output: tagged item performance array.
   - **Step 2: optimisation_reason** — OpenAI Responses API call with the tagged performance data and menu structure. Agent generates a structured change set with the following action types: `section_reorder` (move item within/between sections), `item_rename` (new description/name), `item_suppress` (time-based or permanent availability off), `item_feature` (mark as featured/promoted), `image_queue` (queue image generation for no-image high-priority items), `price_suggestion` (advisory text only — not an executable action).
   - **Step 3: policy_validate** — `Agents::PolicyEvaluator` checks each change action against restaurant `AgentPolicy`. Default policy: `section_reorder`, `item_rename`, `item_suppress`, `item_feature` → `require_approval`. `image_queue` → `auto_approve`. `price_suggestion` → display only (never an approval action).
   - **Step 4: write_change_set** — `Agents::ArtifactWriter` writes the change set as an `AgentArtifact` with type `menu_optimization_changeset`. One `AgentApproval` record per change action that requires approval.
   - **Step 5: notify_manager** — `Agents::ApprovalRouter` sends notification with a link to the change set review screen. Email uses branded mailer layout.
5. Manager review screen (`/restaurants/:id/agent_workbench/optimization`): shows the proposed change set as a visual diff — before (current menu) vs. after (proposed changes applied). Per-change: approve / reject / edit (inline). "Schedule rollout" option: "Apply before [Friday] service" sets a `scheduled_apply_at` timestamp on the artifact.
6. Scheduled application: `ApplyApprovedMenuChangesJob` runs every 30 minutes, checks for artifacts with all approvals resolved and `scheduled_apply_at <= now`, and applies the changes through existing service objects (`MenuitemsController` service path, not direct SQL).
7. A "Preview" mode renders how the SmartMenu would look after all proposed changes are applied — using a temporary in-memory projection (leverages `MenuVersionApplyService` patterns).
8. Image queuing: `image_queue` actions call `generate_menu_image_prompt` tool which enqueues `MenuItemImageGeneratorJob` immediately on auto-approval.
9. Price suggestions are rendered as a separate advisory panel ("Pricing opportunities") in the review screen — they are not part of the approvals workflow and cannot be one-click applied.

## Non-Functional Requirements
- Nightly job must complete for all eligible restaurants within the scheduler window (complete before 06:00 UTC to avoid overlap with Growth Digest jobs).
- All performance reads use the replica DB.
- LLM calls use temperature 0 for the change set generation step to ensure determinism.
- Change actions must be idempotent — re-running the agent for the same period must not create duplicate `AgentApproval` records. Use idempotency key: `restaurant_id + analysis_week + action_type + target_item_id`.
- The agent must not propose the same change action for an item that was rejected in the previous run until at least 14 days have passed. Track rejections in `AgentApproval` table.
- Flipper flag `agent_menu_optimization` must be enabled per restaurant.

## Technical Notes

### New Services
- `agents/workflows/menu_optimization_workflow.rb`

### New Jobs
- `agents/menu_optimization_workflow_job.rb`
- `agents/emit_menu_optimization_events_job.rb` — Heroku Scheduler target
- `agents/apply_approved_menu_changes_job.rb` — runs every 30 minutes, applies approved + scheduled change sets

### Service to Confirm
- Check whether `app/services/menu_optimization_service.rb` or similar exists before building the performance tagging logic in step 1 — reuse if possible.

### Applying Approved Changes
- `section_reorder` → update `Menuitem#position` via existing sort/position service
- `item_rename` → update `Menuitem#name` / `Menuitem#description` via `MenuitemsController` service path
- `item_suppress` → update `Menuitem#available` flag (time-gated: set `available: false` at `suppress_from`, restore at `suppress_until`)
- `item_feature` → update `Menuitem#featured` flag (or equivalent)
- All changes go through existing service objects and trigger existing callbacks (cache invalidation, broadcast, etc.)

### Existing Infrastructure to Leverage
- `MenuVersionApplyService` — use its in-memory projection pattern for Preview mode
- `MenuBroadcastService` — will be called automatically when menuitem records are updated via existing callbacks
- `MenuItemImageGeneratorJob` — called from `image_queue` auto-approved actions

### Idempotency Key
- Add `idempotency_key` (string, unique index) to `AgentApproval` table (migration on Framework spec)
- Key format: `sha256("#{restaurant_id}:#{workflow_run_id}:#{action_type}:#{target_id}")`

### Flipper Flags
- `agent_framework` (required)
- `agent_menu_optimization`

## Acceptance Criteria
1. `EmitMenuOptimizationEventsJob` creates one `AgentDomainEvent` per restaurant with the flag enabled and >= 14 days of data, and skips restaurants below the data threshold.
2. The workflow produces a structured change set artifact containing at least one `section_reorder`, `item_rename`, `item_suppress`, `item_feature`, or `image_queue` action (when sufficient performance data exists to generate a recommendation).
3. `image_queue` actions create `AgentApproval` records with status `auto_approved` and immediately enqueue `MenuItemImageGeneratorJob`.
4. `section_reorder` and `item_rename` actions create `AgentApproval` records with status `pending` — they are never applied without manager review.
5. A `price_suggestion` action never creates an `AgentApproval` record and never results in a `Menuitem#price` update through any code path.
6. A manager approving all pending actions and setting a `scheduled_apply_at` in the future results in `ApplyApprovedMenuChangesJob` applying the changes at or after that time via the standard service layer — not via direct SQL.
7. Re-running the agent for the same restaurant within the same week does not create duplicate `AgentApproval` records (idempotency key enforced at DB level).
8. A change action that was rejected in the previous run is not reproposed until 14 days have passed.
9. The Preview mode renders a visual representation of the menu post-changes without writing any data to the live `Menuitem` table.
10. If the `agent_menu_optimization` flag is disabled mid-run (rare edge case), the `Agents::Runner` checks the flag at the start of each step and halts the run gracefully.

## Out of Scope
- Autonomous application of any change without manager approval (except image queuing).
- Price changes as executable actions — pricing suggestions are advisory text only.
- Cross-restaurant learning or comparative benchmarking.
- Real-time (intra-day) optimisation — this is a nightly/on-demand batch agent.
- A/B testing of menu changes (see Menu Experiments spec #11 — that feature handles controlled experiments).

## Open Questions
1. Does `app/services/menu_optimization_service.rb` or equivalent exist? Confirm before building step 1 data aggregation — reuse the existing service if it covers item-level performance tagging.
2. Should `item_suppress` support time-gated suppression (e.g. "hide Sea Bass after 20:00") in v1? This requires a scheduled job to toggle availability at the specified time. Recommendation: include time-gated suppression in v1 as it is a key differentiator, but confirm engineering capacity.
3. How should the agent handle a restaurant with a very new account (< 14 days of data)? Recommendation: skip with a back-office message ("Not enough data yet — check back after 2 weeks of orders"). The 14-day threshold in the Scheduler trigger handles this, but the on-demand trigger also needs a guard.
