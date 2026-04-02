---
name: Restaurant Growth Agent v1 implementation decisions
description: Restaurant Growth Agent #19 architecture, key patterns, and gotchas (April 2026)
type: project
---

Restaurant Growth Agent (#19) shipped April 2026. 5-step pipeline: read_performance → growth_reason → copy_draft → compose_digest → notify_manager.

**Why:** Closes the loop between raw analytics data and actionable owner insights; read-only + advisory so it was the lowest-risk agent to ship first after #17/#18.
**How to apply:** When touching digest workflows, growth analytics, or marketing copy generation, be aware of these decisions.

## Architecture decisions

- **Workflow class**: `Agents::Workflows::ManagerDigestWorkflow` in `app/services/agents/workflows/`. Same pattern as MenuImportWorkflow — no generic Runner, direct step dispatch.
- **Flipper flags**: `agent_framework` (master) + `agent_growth_digest` (per-restaurant). Both must be enabled for job to run.
- **Domain event**: `manager_digest.scheduled` — emitted by `EmitManagerDigestEventsJob` weekly. `manager_digest.requested` — on-demand from controller.
- **Digest is auto_approved**: No `AgentApproval` records created. ArtifactWriter creates draft, then `update_column(:status, 'approved')` immediately. This is by design — advisory digests never gate on human approval.
- **Email recipients**: All `Employee` records with `role: [:manager, :admin]` and active status for the restaurant. Queried via `managers_and_owners` helper.
- **On-demand path**: Controller bypasses `Agents::Dispatcher` (which only handles `manager_digest.scheduled`). Creates `AgentWorkflowRun` directly + enqueues `ManagerDigestWorkflowJob.perform_later`.
- **Duplicate guard**: Controller and scheduler both check for existing active growth_digest run before creating a new one. Uses `AgentWorkflowRun.active` scope.
- **New tool**: `Agents::Tools::DraftMarketingCopy` — temperature 0.7, returns `{ instagram_caption:, email_body: }` with safe error rescue (returns empty strings on failure).
- **Minimum order threshold**: 5 orders in past 7 days for scheduler eligibility. On-demand bypasses this check.
- **Fallback behaviour**: If no tagged_items or LLM parse error, `fallback_growth_reason` returns raw top_movers/slow_movers from the perf data. No exception raised to web tier.
- **Digest retention**: History view shows last 8 weeks via `DIGEST_HISTORY_WEEKS` constant. Query uses `created_at >=` rather than deletion.
- **New Stimulus controller**: `clipboard_controller.js` — general-purpose clipboard copy with 2-second success feedback. Registered as `clipboard`. Must be in `app/assets/config/manifest.js`.

## Gotchas

- **Fixture conflict in controller tests**: `agent_workflow_runs.yml` has a `running_run` fixture with `workflow_type: growth_digest` for restaurant one. The duplicate-run guard fires in tests unless you explicitly update that run's status first (`update_all(status: 'cancelled')`).
- **Stub pattern for OpenAI in workflow tests**: Use `Object.new.tap { |o| o.define_singleton_method(:chat_with_tools) { |**_| response } }` — NOT Minitest::Mock, which fails on keyword argument matching.
- **Step output keys are symbol keys within workflow**: `step_copy_draft` returns `featured_item: { menuitem_id:, name: }` (symbol keys). But JSONB round-trips produce string keys in subsequent steps. Access with `output['featured_item']` (string) when reading from completed steps, `:featured_item` (symbol) when returned fresh from a method.
- **clipboard_controller.js must be in manifest.js** — asset precompile fails otherwise in test integration tests. Added at `//= link controllers/clipboard_controller.js`.
- **`managers_and_owners` uses `Employee#status: :active` scope** — inactive employees are excluded. Uses enum value `:active`.
- **Performance data uses `ApplicationRecord.connected_to(role: :reading)` block** — all Ordritem/Menuitem queries in `build_tagged_items` run on the replica.
