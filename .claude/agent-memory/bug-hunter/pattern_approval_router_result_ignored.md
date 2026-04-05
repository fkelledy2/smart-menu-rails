---
name: ApprovalRouter.call result ignored — approvals_created inflated and concurrent RecordNotUnique unrescued
description: step_write_change_set ignored ApprovalRouter result and didn't rescue RecordNotUnique on concurrent auto-approve retries (FIXED)
type: project
---

In `MenuOptimizationWorkflow#step_write_change_set`:

1. `Agents::ApprovalRouter.call(...)` return value was discarded — `approvals_created += 1` ran unconditionally even when the router returned `success?: false`. Manager would see inflated approval counts in logs.

2. The `auto_approve` branch called `AgentApproval.create!` without rescuing `ActiveRecord::RecordNotUnique`. If a Sidekiq retry raced past the `exists?(idempotency_key:)` check, the second create would raise `RecordNotUnique` (uncaught), crash the step, and mark the run as failed.

Fixed to: (a) only increment `approvals_created` when `router_result.success?`, (b) rescue `RecordNotUnique` in the auto-approve branch with a `next`.

**Why:** The `exists?` idempotency check is a TOCTOU race — two concurrent workers can both pass it. The DB unique index is the real guard, but the app must handle the resulting exception gracefully.

**How to apply:** Whenever iterating to create records with idempotency keys, always rescue `RecordNotUnique` on the create and treat it as a successful skip. Always check service call result objects before counting successes.
