---
name: write_change_set sets idempotency_key on wrong approval under concurrent retries
description: After ApprovalRouter.call, the code re-queries last approval by created_at desc instead of using the returned approval object — races under concurrent Sidekiq retries
type: project
---

`step_write_change_set` (menu_optimization_workflow.rb lines 285-294):
```ruby
Agents::ApprovalRouter.call(...)
last_approval = @run.agent_approvals.order(created_at: :desc).first
last_approval&.update_column(:idempotency_key, ikey)
```

`ApprovalRouter.call` returns a `Result` struct with `.approval`. Instead of using `result.approval`, the code re-queries the database by `created_at desc` to find the "last" approval. Under concurrent Sidekiq retries, this can pick up a different approval record and stamp the wrong `idempotency_key` on it.

**Fix:** Use `result.approval.update_column(:idempotency_key, ikey)` directly from the returned result object.

**How to apply:** Look for this pattern whenever approval router is called and idempotency_key needs to be set post-create.
