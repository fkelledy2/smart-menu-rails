---
name: Agent Framework v1 (#17)
description: Agent Framework v1 implementation decisions, architecture, and gotchas (April 2026)
type: project
---

Seven new DB tables: `agent_workflow_runs`, `agent_workflow_steps`, `agent_artifacts`, `agent_approvals`, `agent_policies`, `tool_invocation_logs`, `agent_domain_events`.

**Why:** Foundation for all AI agent work (menu import, growth digest, etc.); no individual agent can ship without this.

**How to apply:** All future agent work builds on top of this framework. Key patterns to follow:

Architecture decisions made:
- Domain event polling (not LISTEN/NOTIFY) — PgBouncer compatible. Polls every 1 minute via `Agents::PollDomainEventsJob` cron.
- OpenAI-only in v1 with `OpenaiClient#chat_with_tools` method. Provider abstraction built in anticipation of future multi-provider.
- `AgentPolicy` admin-managed only in v1; owner self-service is v2.
- Five dedicated Sidekiq queues: `agent_critical` (10), `agent_realtime` (8), `agent_high` (5), `agent_default` (3), `agent_low` (1).
- Flipper flag `agent_framework` must be enabled per-restaurant before any workflow runs.
- `AgentArtifact` stores content in jsonb; no external blob storage in v1.
- No DB transaction spans an LLM API call — fetch/reason/write are separate steps in `Agents::Runner`.
- `ArtifactWriter` is the ONLY service that creates `AgentArtifact` records — agents never write to production models directly.

Key gotchas:
- `agent_workflow_steps` has a unique constraint on `(agent_workflow_run_id, step_index)` — test fixtures must not share the same index for the same run.
- `AgentPolicy` scoping: restaurant-scoped rows override global (restaurant_id IS NULL) rows. Order: `restaurant_id IS NULL ASC` puts restaurant-scoped first.
- `ArtifactWriter` rescues both `RecordInvalid` AND `RecordNotNullViolation` (PG raises the latter when run is unsaved).
- `AgentDomainEvent.publish!` uses find-before-create pattern (not `create_or_find_by!`) to avoid raising `RecordInvalid` on uniqueness validation.
- `approve!/reject!` URL path: `/restaurants/:restaurant_id/agent_workbench/:agent_workbench_id/approvals/:id/approve` — the parent run ID is `agent_workbench_id` in route params.
- Tool registration happens in `config/initializers/agent_toolbox.rb` via `Rails.application.config.after_initialize`.
- `Agents::Dispatcher.registry` is a class-level `@registry` hash; tests must clean up after themselves with `teardown`.
