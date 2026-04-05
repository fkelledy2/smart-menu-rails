---
name: ApprovalRouter idempotency_key set via separate update_column — TOCTOU race under concurrent Sidekiq retries
description: step_write_change_set called ApprovalRouter.call (creates record with nil idempotency_key) then update_column(:idempotency_key) — concurrent workers both pass the exists? check and both create records, second update_column raises RecordNotUnique (FIXED)
type: project
---

In `MenuOptimizationWorkflow#step_write_change_set`, the idempotency check was:

```ruby
next if AgentApproval.exists?(idempotency_key: ikey)  # passes — column is nil on new records
result = Agents::ApprovalRouter.call(...)              # creates record with idempotency_key: nil
result.approval&.update_column(:idempotency_key, ikey) # sets column AFTER create
```

Between the `create!` and `update_column` calls, a second concurrent worker passes the `exists?` check (the column is still nil on the just-created record) and creates a duplicate. The second `update_column` violates the partial unique index on `agent_approvals.idempotency_key`, raising `RecordNotUnique` and failing the entire step.

**Fix:** Pass `idempotency_key:` directly to `ApprovalRouter.call` (and thread it through to `AgentApproval.create!`) so the key is set atomically at creation time.

**How to apply:** Any service that creates records with a deferred uniqueness key is susceptible to this pattern. Always set the key at `create!` time, never in a follow-up `update_column`.
