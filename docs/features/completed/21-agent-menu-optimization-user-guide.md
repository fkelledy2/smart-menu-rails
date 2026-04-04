# Menu Optimisation Agent — User Guide

## What It Does

The Menu Optimisation Agent analyses your restaurant's menu performance every night and generates a concrete set of proposed changes — not just observations — that you can review, approve, and schedule for rollout in one session.

Unlike the Growth Digest (which gives you advisory text), this agent produces a structured **change set** with specific actions:

| Action | What it does |
|--------|-------------|
| **Item Rename** | Suggests an improved name or description for a slow or friction item |
| **Section Reorder** | Moves an item to a better position within its section |
| **Item Suppress** | Hides a persistent slow mover (temporarily or permanently) |
| **Item Feature** | Makes a high-margin item visible/prominent |
| **Image Queue** | Queues AI image generation for high-priority items with no image |
| **Price Suggestion** | Advisory pricing recommendation (never applied automatically) |

## Getting Started

### 1. Enable the Flipper flags

Two flags must be enabled for a restaurant:

- `agent_framework` — required for all AI agents
- `agent_menu_optimization` — specific to this agent

Enable them via the Flipper admin UI at `/flipper` or via Rails console:

```ruby
Flipper.enable(:agent_framework, restaurant)
Flipper.enable(:agent_menu_optimization, restaurant)
```

### 2. Wait for sufficient order history

The agent requires at least **14 days of order history** before it can generate meaningful recommendations. If you trigger it on a newer account, you'll see a notice explaining this.

### 3. Access the optimisation screen

From the restaurant back office, go to:

**AI Workbench → Menu Optimisation**

Or navigate directly to:
```
/restaurants/:id/agent_workbench/optimization
```

## Running an Analysis

### Automatic (nightly)

`EmitMenuOptimizationEventsJob` runs every night at 02:00 UTC via Heroku Scheduler. It automatically creates one analysis run per eligible restaurant.

### On-demand

Click **"Run Analysis Now"** on the optimisation screen. The analysis completes within a few minutes and you'll see the new change set listed on the page.

## Reviewing and Approving Changes

When the analysis completes, you'll receive an email with a link to the review screen. You can also navigate there from the optimisation list.

The review screen has three columns:

### Left: Pending Approvals

Each proposed change shows:
- The **action type** (e.g. Item Rename, Item Feature)
- The **target item** name
- The **reason** the agent recommends this change
- For renames: the proposed new name and/or description

**Approve** the change to include it in the rollout.
**Reject** the change to exclude it (and prevent it from being re-proposed for 14 days).

### Right: Pricing Opportunities (Advisory)

Price suggestions are shown in a separate advisory panel. These are **never applied automatically** and never have Approve/Reject buttons. They are for your information only.

### Right: Preview

Once you approve some changes, a live preview appears showing how your menu would look with those changes applied — before anything is written to the live menu.

## Scheduling a Rollout

Once all pending approvals are resolved (approved or rejected):

1. A **"Schedule Rollout"** form appears at the bottom of the review screen.
2. Pick a date and time (e.g. "before Friday evening service").
3. Click **Schedule Rollout**.

`ApplyApprovedMenuChangesJob` runs every 30 minutes and applies the changes at or after your chosen time. Changes flow through the standard service layer — cache invalidation, broadcasts, and all existing callbacks fire normally.

## What Gets Applied

Only **approved** actions are applied at rollout time:

- **Item Rename** → updates `Menuitem#name` and/or `#description`
- **Section Reorder** → updates `Menuitem#sequence`
- **Item Suppress** → sets `Menuitem#hidden = true`
- **Item Feature** → sets `Menuitem#hidden = false`
- **Image Queue** → already enqueued at approval time (no change at rollout)

**Price suggestions are never applied** through any code path.

## Idempotency and Repeat Runs

- Re-running the agent within the same ISO calendar week will not create duplicate approval records (enforced via unique index on `idempotency_key`).
- If you reject a change, that specific action will not be re-proposed for **14 days**.
- The agent checks the `agent_menu_optimization` Flipper flag at each pipeline step. If the flag is disabled mid-run, the run halts gracefully with a `failed` status.

## Technical Reference

### Jobs

| Job | Schedule | Purpose |
|-----|----------|---------|
| `Agents::EmitMenuOptimizationEventsJob` | Nightly 02:00 UTC (Heroku Scheduler) | Emits one domain event per eligible restaurant |
| `Agents::MenuOptimizationWorkflowJob` | On-demand via dispatcher | Runs the 5-step analysis pipeline |
| `Agents::ApplyApprovedMenuChangesJob` | Every 30 minutes (Heroku Scheduler) | Applies approved change sets at `scheduled_apply_at` |

### Flipper Flags

| Flag | Purpose |
|------|---------|
| `agent_framework` | Required for all AI agents |
| `agent_menu_optimization` | Enables this specific agent |

### Workflow Steps

1. **read_performance** — tags each menu item by margin, conversion, and sales velocity using the replica DB
2. **optimisation_reason** — LLM (GPT-4o, temperature 0) generates structured change set
3. **policy_validate** — classifies each action as `auto_approve`, `require_approval`, or `advisory`
4. **write_change_set** — creates `AgentArtifact` + `AgentApproval` records
5. **notify_manager** — sends branded email with link to review screen

### Artifact and Approval Records

- **`AgentArtifact`** (type: `menu_optimization_changeset`) — holds the full change set JSON
- **`AgentApproval`** — one per approvable action, with `idempotency_key` to prevent duplicates
- **`AgentArtifact#scheduled_apply_at`** — set when rollout is scheduled; cleared to `applied` status after `ApplyApprovedMenuChangesJob` runs
