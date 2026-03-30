# Restaurant Growth Agent

## Status
- Priority Rank: #19 (Phase 1 agent — ship alongside or immediately after Menu Import Agent)
- Category: Post-Launch — agent tier, Phase 1
- Effort: M
- Dependencies: Agent Framework (#17), `RestaurantInsightsService` (exists), `ProfitMarginAnalyticsService` (exists), `AnalyticsService` (exists), Sidekiq scheduler, OpenAI API

## Problem Statement
Restaurant owners are time-poor during service and rarely have capacity for strategic analysis. The platform already collects rich data — order volumes, item-level margin, cover counts, menu browse rates — but this data lives in raw analytics dashboards that require owners to interpret it themselves. The majority of restaurant owners do not have the time or analytical background to surface actionable insights from raw numbers. The Restaurant Growth Agent closes this gap by running a weekly synthesis pass over the restaurant's performance data and delivering a concise, opinionated digest: what worked, what didn't, what to change before the weekend, and ready-to-use marketing copy — all delivered to the manager's back office and inbox without them having to ask. This is the lowest-risk agent to ship first because it is read-only plus advisory: the agent never writes to live data autonomously.

## Success Criteria
- Every restaurant with the feature enabled receives a weekly digest by 08:00 Monday morning their local time.
- The digest contains: top 5 revenue items, bottom 5 items with a suggested action, at least one repricing opportunity, at least one menu friction highlight, a weekend recommendation, and 1–2 social media copy drafts.
- Managers can action any recommendation with a single click from the digest card (e.g. "Edit this item", "Generate image", "View orders").
- The agent never sends any communication to customers autonomously — all outbound is manager-initiated.
- The digest open rate is measurable (tracked via existing email analytics or pixel/link tracking).

## User Stories
- As a restaurant owner, I want a weekly summary of my best and worst performers delivered to my inbox so I can make better decisions without trawling through dashboards.
- As a restaurant manager, I want specific, actionable menu change suggestions I can act on before the weekend service, not just raw data.
- As a restaurant owner, I want ready-to-use social media copy for my specials so I don't have to write it from scratch.
- As a restaurant owner, I want to be able to request a digest on-demand, not just on a weekly schedule.

## Functional Requirements

1. `Agents::Dispatcher` maps the `manager_digest.scheduled` domain event to `Agents::ManagerDigestWorkflowJob` on the `agent_default` Sidekiq queue.
2. Heroku Scheduler enqueues `EmitManagerDigestEventsJob` weekly (Monday 06:00 UTC). This job writes one `AgentDomainEvent` per restaurant that has the `agent_growth_digest` Flipper flag enabled and has sufficient order data (>= 5 orders in the past 7 days). It does not run agent logic directly.
3. The workflow pipeline:
   - **Step 1: read_performance** — read 7-day metrics per item: order count, revenue contribution, margin (from `ProfitMarginAnalyticsService`), browse-to-order conversion rate (from `AnalyticsService`), average preparation time, cover count by day. Use replica DB. Tag each item as: top_mover / slow_mover / high_margin / low_margin / high_friction / low_friction.
   - **Step 2: growth_reason** — OpenAI Responses API call with the tagged item data and restaurant context. Agent identifies: top performers, underperformers with suggested action (remove/reprice/reimage), repricing candidates (high conversion + low margin), friction items (high browse + low order conversion). Output: structured JSON change set.
   - **Step 3: copy_draft** — second LLM call to generate marketing copy: 1 Instagram caption and 1 short email body for the highest-margin special or featured item. Use restaurant name, establishment type, and item descriptions as context.
   - **Step 4: compose_digest** — `compose_manager_summary` tool assembles the final digest artifact: ranked insights, action links, marketing copy, weekend recommendation.
   - **Step 5: notify_manager** — write `AgentArtifact` with type `growth_digest`, status `approved` (digests are advisory — no approval gate required). Send digest email via `AgentDigestMailer`. Create back-office digest card.
4. All digest recommendations are advisory only — they do not create `AgentApproval` records. The policy for all growth digest actions is `auto_approve` (display only).
5. Back-office digest card at `/restaurants/:id/dashboard` shows the latest digest with: summary narrative, insight list with action buttons, and marketing copy with copy-to-clipboard controls.
6. Each insight action button deep-links to the relevant back-office page: "Edit this item" → menuitem edit page, "Generate image" → triggers `MenuItemImageGeneratorJob`, "View orders" → filtered orders list.
7. On-demand digest: a "Generate Now" button in the back-office dashboard emits `manager_digest.requested` domain event and enqueues the workflow immediately.
8. Marketing copy display includes a one-click "Copy to clipboard" button. A "Share to Instagram" stub is present but deactivated in v1 (marked as "coming soon").
9. Digest history: the last 8 digest artifacts are retained and accessible from the AI Workbench for the restaurant.

## Non-Functional Requirements
- The weekly digest job must complete within 10 minutes per restaurant to ensure all restaurants are processed before Monday morning service.
- All analytics reads must use the replica DB to avoid impacting primary write performance.
- LLM calls use temperature 0.3 for reasoning steps and temperature 0.7 for marketing copy generation to balance accuracy with creative variation.
- If the OpenAI API is unavailable, the job retries 3 times with exponential backoff. If all retries fail, the manager receives a simplified digest containing only the raw data summary (no LLM-generated insights).
- Digest emails use the branded mailer layout (Feature #2 dependency).
- Flipper flag `agent_growth_digest` must be enabled per restaurant.

## Technical Notes

### New Services (`app/services/agents/workflows/`)
- `agents/workflows/manager_digest_workflow.rb` — orchestrates the 5-step pipeline

### New Jobs (`app/jobs/agents/`)
- `agents/manager_digest_workflow_job.rb` — receives `restaurant_id`, creates/resumes `AgentWorkflowRun`
- `agents/emit_manager_digest_events_job.rb` — weekly Scheduler trigger; writes `AgentDomainEvent` per eligible restaurant

### New Mailer
- `app/mailers/agent_digest_mailer.rb` — `weekly_digest` and `on_demand_digest` methods, uses branded layout

### Existing Services to Read (read-only; do not modify their interfaces)
- `RestaurantInsightsService` — primary data feed for the agent
- `ProfitMarginAnalyticsService` — item-level margin data
- `AnalyticsService` — browse/order conversion event data
- `InventoryProfitAnalyzerService` — stock pressure signals

### Tools Used (from Toolbox)
- `read_restaurant_context` — menu structure, pricing, establishment type, trading hours
- `search_menu_items` — filter by performance bucket, margin, tag
- `compose_manager_summary` — narrative summary with ranked insights
- `propose_menu_patch` — generates specific change recommendations for weekend (advisory only — writes to artifact, not live data)

### New Tool
- `draft_marketing_copy` (add to `Agents::Toolbox`) — calls OpenAI with item/restaurant context, returns Instagram and email copy strings. Input schema: `{ item_name:, item_description:, restaurant_name:, establishment_type:, tone: }`.

### Controller
- Add `agent_workbench#digest_card` partial render to existing restaurant dashboard
- Add `GET /restaurants/:id/agent_workbench/digests` index action listing digest history

### Flipper Flags
- `agent_framework` — master switch (required)
- `agent_growth_digest` — per-restaurant enablement

### DB Query Notes
- All 7-day metric aggregations must run on the replica. Use `ApplicationRecord.connected_to(role: :reading)` pattern.
- Aggregate queries across `Ordritem`, `Menuitem`, and analytics event tables must respect the 15s replica statement timeout.
- Consider materialised view extension or pre-aggregated daily rollup table if per-restaurant query time exceeds 10s for restaurants with > 1,000 orders per week.

## Acceptance Criteria
1. `EmitManagerDigestEventsJob` running at 06:00 UTC on Monday creates one `AgentDomainEvent` per restaurant with `agent_growth_digest` enabled and >= 5 orders in the past 7 days, and does not create events for restaurants below that threshold.
2. The workflow creates an `AgentWorkflowRun` and 5 `AgentWorkflowStep` records for the restaurant.
3. After step 1, every `Menuitem` in the restaurant has been tagged as one of: top_mover, slow_mover, high_margin, low_margin, high_friction, low_friction in the step's `output_snapshot`.
4. After step 5, an `AgentArtifact` of type `growth_digest` with status `approved` exists for the restaurant.
5. The manager receives a digest email that includes: at least one item from each of the bottom-performer / repricing / friction categories, a weekend recommendation, and at least one marketing copy block.
6. The back-office digest card renders the latest digest with actionable deep-links.
7. Clicking "Generate Now" from the dashboard emits a domain event and the digest appears within 10 minutes.
8. If the OpenAI API returns a 500 error on all retries, the manager receives a fallback digest containing only the raw performance data table — no unhandled exception reaches the web tier.
9. Digest artifacts older than 8 weeks are not returned in the digest history view (retention policy enforced at query level, not deletion).
10. All analytics reads in the workflow use the replica DB connection.

## Out of Scope
- Automatic application of any menu change — all recommendations are advisory only.
- Direct social media posting (Instagram, Facebook API integration) — copy-to-clipboard only in v1.
- Customer-facing communications generated by this agent.
- Cross-restaurant benchmarking ("your margins vs. similar restaurants") — post-launch.
- Personalised digest frequency (weekly is fixed in v1; configurable cadence is v2).

## Open Questions
1. Should the digest email be delivered per-restaurant or per-user (manager)? If a restaurant has multiple managers, do they all receive it? Recommendation: deliver to all users with `manager` or `owner` role for the restaurant — confirm the role structure.
2. What is the minimum data threshold for a meaningful digest? Recommendation: 5 orders in the past 7 days — but this needs product validation. A restaurant that was closed all week should not receive an empty digest.
3. Should marketing copy be generated even for restaurants with a very limited menu (e.g. 5 items)? Recommendation: yes, with a simpler prompt — but the copy quality will vary. Flag this as a known edge case.
