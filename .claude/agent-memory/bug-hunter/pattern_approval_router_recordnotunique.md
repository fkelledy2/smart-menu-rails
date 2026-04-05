---
name: ApprovalRouter RecordNotUnique not rescued (require_approval path)
description: ApprovalRouter.call only rescues RecordInvalid; concurrent Sidekiq retries on require_approval path hit RecordNotUnique and fail the entire workflow run
type: project
---

ApprovalRouter#call rescued `ActiveRecord::RecordInvalid` but not `ActiveRecord::RecordNotUnique`. When MenuOptimizationWorkflow calls ApprovalRouter with an idempotency_key and a concurrent retry races past the `exists?` guard, the DB unique index raises `RecordNotUnique` which propagates through `execute_step` → outer `rescue StandardError` → `@run.mark_failed!`. The entire workflow run is marked failed on a benign duplicate.

**Fix applied:** Added `rescue ActiveRecord::RecordNotUnique` before `RecordInvalid` rescue in `app/services/agents/approval_router.rb` — looks up the existing approval by idempotency_key and returns a success Result.

**Why:** Agent workflows using `require_approval` disposition pass idempotency keys. Sidekiq retries on transient errors can re-enter the loop after the first attempt already created the approval record.

**How to apply:** Always rescue `RecordNotUnique` separately before `RecordInvalid` when creating records with unique constraints. `RecordNotUnique` is a subclass of `StatementInvalid`, not `RecordInvalid`.
