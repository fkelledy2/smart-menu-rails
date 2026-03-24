# Agent Framework — Shared Infrastructure

## Status
- Priority Rank: #15 (first among all AI agent work; post-launch)
- Category: Post-Launch — prerequisite for all individual agents
- Effort: L
- Dependencies: Rails 7.2 app foundation, Sidekiq/Redis, PostgreSQL, OpenAI API key

## Problem Statement
Before any individual AI agent can be shipped, the platform needs a shared infrastructure layer that handles: workflow execution and state persistence, step-level resumability, an approval/policy gate between the agent and live data, audit logging, and a consistent back-office UI for reviewing and acting on agent proposals. Without this foundation, each agent would build its own ad-hoc pipeline, duplicating infrastructure and creating inconsistent behaviour. This spec defines the shared Agent Framework that every subsequent agent (Menu Import, Menu Optimization, Restaurant Growth, etc.) is built on top of.

## Success Criteria
- An `AgentWorkflowRun` can be created, executed step-by-step, paused, resumed, and completed without data loss across Sidekiq worker restarts.
- Every agent action that modifies data goes through `Agents::PolicyEvaluator` — no agent writes to live data without either auto-approval or a human approval step.
- A manager can view all workflow runs for their restaurant, see step-level progress, and approve, reject, or retry individual steps from the back-office AI Workbench UI.
- All tool calls are logged in `ToolInvocationLog` — no silent mutations.
- The framework supports at least five Sidekiq queues with distinct priority routing.
- An agent run that fails mid-step resumes from the last successful step on retry — it does not re-run the entire pipeline.

## User Stories
- As a restaurant owner, I want to see a history of all AI actions taken on my account so I can audit what the system has done.
- As a restaurant manager, I want to approve or reject AI-proposed changes before they affect my live menu or communications.
- As a developer building a new agent, I want a standard framework so I don't have to re-implement workflow state, approval routing, or audit logging per agent.
- As an admin/operator, I want to see aggregate agent activity across all restaurants for monitoring and debugging purposes.

## Functional Requirements

1. **AgentWorkflowRun model**: persists `restaurant_id`, `workflow_type` (string enum), `trigger_event` (string), `status` (pending / running / awaiting_approval / completed / failed / cancelled), `started_at`, `completed_at`, `error_message` (text), and `context_snapshot` (jsonb — input state at trigger time).
2. **AgentWorkflowStep model**: belongs to `AgentWorkflowRun`, persists `step_name`, `step_index` (integer), `status` (pending / running / completed / failed / skipped), `input_snapshot` (jsonb), `output_snapshot` (jsonb), `started_at`, `completed_at`, `retry_count`, `last_error` (text). Steps are created up-front for the entire pipeline so progress is visible from the start.
3. **AgentArtifact model**: belongs to `AgentWorkflowRun`, persists `artifact_type` (string), `content` (jsonb), `status` (draft / approved / rejected / applied), `approved_by_id` (FK to User), `approved_at`. Artifacts are the outputs of a run — they are never applied to live data until status is `approved` or the policy marks them auto-approvable.
4. **AgentApproval model**: belongs to `AgentWorkflowRun` or `AgentWorkflowStep`, persists `action_type`, `risk_level` (low / medium / high), `proposed_payload` (jsonb), `status` (pending / approved / rejected / expired), `reviewer_id` (FK to User), `reviewed_at`, `reviewer_notes` (text), `expires_at`.
5. **AgentPolicy model**: belongs to `Restaurant` (scoped per restaurant), persists `action_type` (string), `auto_approve` (boolean), `escalation_email` (string), `active` (boolean). Default policies are seeded from a global default table on restaurant creation.
6. **ToolInvocationLog model**: belongs to `AgentWorkflowStep`, persists `tool_name`, `input_params` (jsonb), `output_payload` (jsonb), `status` (success / error / timeout), `duration_ms` (integer), `invoked_at`.
7. **`Agents::Dispatcher` service**: receives a domain event payload, looks up the registered workflow type for that event, and enqueues the correct workflow job on the appropriate Sidekiq queue. Logs the dispatch decision. Idempotent — duplicate events for the same run do not enqueue a second job.
8. **`Agents::Runner` service**: receives a `AgentWorkflowRun`, executes each `AgentWorkflowStep` in sequence, calls the OpenAI Responses API for reasoning steps, persists all step state, handles per-step retries (max 3), and calls `Agents::PolicyEvaluator` before any write action.
9. **`Agents::Toolbox`**: a registry of callable tool objects (service object wrappers). Each tool has a `name`, `description`, `input_schema` (jsonb), and a `call(params)` method. Tools call existing service objects — they do not contain business logic themselves. Every call is wrapped in `ToolInvocationLog` persistence.
10. **`Agents::PolicyEvaluator` service**: receives `action_type`, `restaurant_id`, and `proposed_payload`. Returns `:auto_approve`, `:require_approval`, or `:blocked`. Checks against `AgentPolicy` records for the restaurant, falling back to global defaults.
11. **`Agents::ArtifactWriter` service**: receives a workflow run and structured output, writes an `AgentArtifact` with status `draft`. Never mutates live `Menuitem`, `Ordr`, or any other production model directly.
12. **`Agents::ApprovalRouter` service**: creates an `AgentApproval` record, determines the correct reviewer (restaurant owner or manager based on `risk_level`), and sends a notification via the existing mailer infrastructure.
13. **Domain event table**: `agent_domain_events` table with `event_type`, `source_type` (polymorphic), `source_id`, `payload` (jsonb), `processed_at`, `idempotency_key` (unique index). The Dispatcher queries this table — it does not receive events inline.
14. **Sidekiq queue configuration**: five named queues — `agent_critical`, `agent_realtime`, `agent_high`, `agent_default`, `agent_low` — defined in `config/sidekiq.yml` with appropriate concurrency and weight settings.
15. **Back-office AI Workbench UI** (`/restaurants/:id/agent_workbench`): lists all `AgentWorkflowRun` records for the restaurant with status, workflow type, trigger, timestamps. Drill-down per run shows: step-level timeline, artifact diff view, pending approvals with approve/reject/edit controls, and tool invocation log.
16. **Approval notification**: when a run enters `awaiting_approval`, the `AgentApprovalMailer` sends a notification to the reviewer with a deep link to the workbench approval screen.
17. **Expiry**: `AgentApproval` records expire after 72 hours by default (configurable per policy). An `ExpireAgentApprovalsJob` runs every hour to mark expired approvals and notify the restaurant owner.

## Non-Functional Requirements
- Agent jobs must never run inside a web request. All work is enqueued to Sidekiq and executed on worker dynos.
- Workflow runs are resumable: if a Sidekiq job is killed mid-step, re-enqueueing the job resumes from the last completed step, not the beginning.
- All tool calls must be idempotent — safe to retry without double-mutations.
- No agent job should hold a DB transaction open across an LLM API call. Fetch → reason → write are separate steps.
- The LLM call uses the OpenAI Responses API (function-calling / tool-use interface). The `openai_client.rb` service is extended, not replaced.
- Statement timeout applies: 5s for primary DB writes, 15s for replica reads within agent jobs.
- All `AgentArtifact` content is stored in PostgreSQL jsonb columns — no external blob storage for v1.
- Flipper flag `agent_framework` must be enabled per restaurant before any agent workflows run.

## Technical Notes

### New Models / Migrations
- `create_agent_workflow_runs` — restaurant_id FK, workflow_type, trigger_event, status, started_at, completed_at, error_message, context_snapshot (jsonb)
- `create_agent_workflow_steps` — workflow_run_id FK, step_name, step_index, status, input_snapshot (jsonb), output_snapshot (jsonb), started_at, completed_at, retry_count, last_error
- `create_agent_artifacts` — workflow_run_id FK, artifact_type, content (jsonb), status, approved_by_id FK, approved_at
- `create_agent_approvals` — workflow_run_id FK, step_id FK (nullable), action_type, risk_level, proposed_payload (jsonb), status, reviewer_id FK, reviewed_at, reviewer_notes, expires_at
- `create_agent_policies` — restaurant_id FK, action_type, auto_approve, escalation_email, active
- `create_tool_invocation_logs` — step_id FK, tool_name, input_params (jsonb), output_payload (jsonb), status, duration_ms, invoked_at
- `create_agent_domain_events` — event_type, source_type, source_id, payload (jsonb), processed_at, idempotency_key (unique index)

### New Services (`app/services/agents/`)
- `agents/dispatcher.rb`
- `agents/runner.rb`
- `agents/toolbox.rb`
- `agents/policy_evaluator.rb`
- `agents/artifact_writer.rb`
- `agents/approval_router.rb`

### Tool Objects (`app/services/agents/tools/`)
Initial tool set:
- `tools/fetch_menu_source.rb` — wraps `PdfMenuProcessor` / `WebMenuProcessor`
- `tools/read_restaurant_context.rb` — reads Restaurant, menus, sections, items, settings
- `tools/search_menu_items.rb` — filtered query via `Menuitem` with allergen/tag/section/price scope
- `tools/propose_menu_patch.rb` — writes structured diff to `AgentArtifact` via `ArtifactWriter`
- `tools/generate_menu_image_prompt.rb` — queues `MenuItemImageGeneratorJob` for items without images
- `tools/flag_item_unavailable.rb` — creates an `AgentApproval` for staff confirmation before 86'ing
- `tools/compose_manager_summary.rb` — calls OpenAI to generate a narrative summary string
- `tools/create_review_queue_task.rb` — creates an `AgentApproval` and routes to manager
- `tools/write_draft_translation.rb` — enqueues `MenuLocalizationJob` for flagged items

### New Jobs (`app/jobs/agents/`)
- `agents/dispatch_domain_event_job.rb` — processes unprocessed `AgentDomainEvent` records
- `agents/expire_agent_approvals_job.rb` — marks expired `AgentApproval` records, notifies owner

### New Policies (`app/policies/`)
- `agent_workflow_run_policy.rb` — restaurant owner/manager can view and approve their own runs
- `agent_artifact_policy.rb` — restaurant owner/manager can view and act on their own artifacts
- `agent_policy_policy.rb` — restaurant owner can manage policy settings; admin can see all

### New Mailer
- `app/mailers/agent_approval_mailer.rb` — sends approval request and expiry notifications using branded layout

### Controller
- `app/controllers/restaurants/agent_workbench_controller.rb` — index (run list), show (run detail), approve/reject actions
- Route: `resources :agent_workbench, only: [:index, :show]` nested under restaurant, plus member actions `approve` and `reject` on the approval resource

### Flipper Flags
- `agent_framework` — master switch; required before any agent workflow can run

### LLM Integration
- Extend `openai_client.rb` to support the Responses API tool-use format
- Agent does not call Rails directly; it calls tools via `Agents::Toolbox`, tools call service objects
- Store raw LLM response in `AgentWorkflowStep#output_snapshot` for debugging

### Sidekiq Queue Config Addition (`config/sidekiq.yml`)
```yaml
queues:
  - [agent_critical, 10]
  - [agent_realtime, 8]
  - [agent_high, 5]
  - [agent_default, 3]
  - [agent_low, 1]
```

## Acceptance Criteria
1. Creating an `AgentWorkflowRun` with status `pending` and enqueuing an `AgentDispatchJob` transitions the run to `running` and creates the expected `AgentWorkflowStep` records before any LLM call is made.
2. Killing the Sidekiq worker mid-run and re-enqueueing the job resumes from the last step with status `completed`, not from step 1.
3. A tool call that the `Agents::PolicyEvaluator` classifies as `require_approval` creates an `AgentApproval` record with status `pending` and sends an approval email — no data is written to the live model.
4. A tool call classified as `auto_approve` by the restaurant's `AgentPolicy` writes an `AgentArtifact` with status `approved` and logs a `ToolInvocationLog` record.
5. An `AgentApproval` older than 72 hours is marked `expired` by `ExpireAgentApprovalsJob` and does not transition to `approved` when a manager later tries to approve it.
6. A restaurant owner can view all runs, steps, artifacts, and tool logs for their restaurant from `/restaurants/:id/agent_workbench` and cannot see runs from other restaurants (Pundit enforced).
7. An admin with `admin?` role can view runs across all restaurants from an admin-namespaced route.
8. The `agent_framework` Flipper flag being off for a restaurant causes `Agents::Dispatcher` to skip enqueuing any workflow job for that restaurant.
9. All new models have corresponding Pundit policies and no endpoint returns data without an authorisation check.
10. No agent job opens a DB transaction that spans an LLM API call.

## Out of Scope
- Any individual agent workflow (menu import, growth digest, etc.) — these are separate specs.
- A/B framework for comparing agent quality.
- Agent-to-agent communication or chaining across restaurant accounts.
- MCP protocol exposure (separate spec: MCP AI Agent Wrapper).
- Multi-modal LLM inputs (image, voice) in this iteration.
- Billing or cost tracking for LLM API token consumption (post-launch).

## Open Questions
1. Should `AgentPolicy` records be editable by the restaurant owner from a self-service UI in v1, or managed only by mellow.menu admin? Recommendation: admin-managed defaults with an owner override toggle per action type in v2.
2. What is the retention period for `ToolInvocationLog` records? Recommendation: 90 days then archive to cold storage — but legal/compliance needs to confirm.
3. Should the `agent_domain_events` table use a polling approach (Sidekiq cron polls every 30s) or a LISTEN/NOTIFY approach? Note: LISTEN/NOTIFY is incompatible with PgBouncer transaction pooling — polling is safer. Confirm PgBouncer usage before deciding.
4. Is OpenAI the only LLM provider in v1, or should the runner be provider-agnostic from the start? Recommendation: OpenAI-only in v1 with a provider abstraction layer built in anticipation of multi-provider support.
