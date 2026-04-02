# Agent Framework (#17) — User Guide

## What is the Agent Framework?

The Agent Framework is the shared infrastructure that powers all AI-driven workflows on the mellow.menu platform. It lets AI agents perform multi-step tasks (menu import, growth digests, optimization suggestions) while keeping human managers in control via an approval gate before any live data is changed.

---

## Enabling AI Agents for a Restaurant

The Agent Framework is off by default. To activate it for a specific restaurant:

1. Log in as a super_admin.
2. Navigate to `/flipper` (Flipper UI).
3. Search for the `agent_framework` flag.
4. Enable it for the specific restaurant Actor (e.g., `Restaurant;42`).

Once enabled, domain events published for that restaurant will be picked up by the poller and dispatched to the appropriate workflow.

---

## The AI Workbench (Restaurant Back-Office)

### Accessing the Workbench

Restaurant owners and managers with `manager` or `admin` role can access the AI Workbench at:

```
/restaurants/:restaurant_id/agent_workbench
```

The workbench shows:
- All AI workflow runs for the restaurant, with status indicators.
- Drill-down per run showing: step timeline, artifact diff view, tool invocation log, and pending approvals.

### Statuses You Will See

| Status | Meaning |
|--------|---------|
| Pending | The workflow has been queued but not started yet. |
| Running | The AI is actively working through the steps. |
| Awaiting Approval | The AI has proposed an action and is waiting for your approval before proceeding. |
| Completed | All steps finished successfully. |
| Failed | An error occurred. The error message is shown in the run detail. |
| Cancelled | The workflow was stopped. |

---

## Reviewing and Approving AI Proposals

When a workflow enters **Awaiting Approval** status:

1. You will receive an email with a deep link directly to the approval screen.
2. Open the AI Workbench and click the run in question.
3. Under **Approvals**, review the proposed action:
   - Action type (e.g. `Propose Menu Patch`)
   - Risk level (`Low`, `Medium`, or `High`)
   - The proposed payload (click "View proposed payload" to expand)
4. Click **Approve** to allow the action, or **Reject** (with an optional reason) to cancel it.

### Approval Expiry

Approvals expire automatically after a set window (default 72 hours). If you do not act before expiry:
- The approval is marked `expired`.
- You will receive a notification email.
- No changes will be made to your restaurant data.
- To retry, you must trigger a new workflow run.

---

## Understanding the Step Timeline

Each workflow run is broken into named steps. In the run detail view you can see:
- Which steps have completed, are running, or have failed.
- For failed steps: the error message and how many times it was retried (max 3 attempts).
- For each step: a collapsible list of **tool calls** showing the tool name, duration, and status.

---

## Managing Agent Policies

Agent Policies control whether the AI can auto-approve certain actions or must always request human approval. In v1, policies are managed by mellow.menu admin only.

Default policies per restaurant:

| Action Type | Auto-Approve | Risk Level |
|-------------|-------------|------------|
| `read_restaurant_context` | Yes | Low |
| `search_menu_items` | Yes | Low |
| `compose_manager_summary` | Yes | Low |
| `fetch_menu_source` | Yes | Low |
| `create_review_queue_task` | Yes | Low |
| `propose_menu_patch` | No | Medium |
| `flag_item_unavailable` | No | Medium |
| `generate_menu_image` | No | Low |
| `write_draft_translation` | No | Medium |

To request a policy change (e.g., auto-approve menu patches for a high-trust restaurant), contact the mellow.menu team.

---

## For Developers: Publishing a Domain Event

To trigger an agent workflow programmatically, publish an `AgentDomainEvent`:

```ruby
AgentDomainEvent.publish!(
  event_type: 'menu.import_requested',
  payload: { 'restaurant_id' => restaurant.id, 'source_url' => 'https://...' },
  idempotency_key: "menu-import-#{restaurant.id}-#{Date.current}",
)
```

The `PollDomainEventsJob` (runs every minute) will pick this up and dispatch it to the registered workflow type.

---

## For Developers: Registering a New Agent Workflow

To add a new workflow type:

1. Register the event-to-workflow mapping in an initializer or the individual agent's setup:

```ruby
Agents::Dispatcher.register('menu.import_requested', workflow_type: 'menu_import')
```

2. Create the workflow steps up-front in your job before calling `Agents::Runner.call(run)`.

3. Register any new tools with the toolbox:

```ruby
Agents::Toolbox.register(Agents::Tools::YourNewTool)
```

---

## Sidekiq Queues

The agent framework uses five dedicated Sidekiq queues with weighted priority:

| Queue | Priority | Usage |
|-------|----------|-------|
| `agent_critical` | 10 | Time-sensitive agent actions |
| `agent_realtime` | 8 | Near-realtime workflows |
| `agent_high` | 5 | High-priority background workflows |
| `agent_default` | 3 | Standard workflow execution |
| `agent_low` | 1 | Expiry checks and maintenance |

---

## Architecture Summary

```
AgentDomainEvent  →  PollDomainEventsJob  →  Dispatcher
                                                  |
                                          AgentWorkflowRun created
                                                  |
                                    DispatchDomainEventJob  →  Runner
                                                                  |
                                                         per AgentWorkflowStep:
                                                           1. call_llm (no DB tx)
                                                           2. process_tool_calls
                                                              ├─ auto_approve → Toolbox.invoke → ToolInvocationLog
                                                              └─ require_approval → ApprovalRouter → AgentApproval
                                                                                        |
                                                                              AgentApprovalMailer → reviewer
```
