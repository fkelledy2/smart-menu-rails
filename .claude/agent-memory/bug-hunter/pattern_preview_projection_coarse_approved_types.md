---
name: build_preview_projection used coarse approved_types set — same bug as ApplyApprovedMenuChangesJob
description: AgentWorkbenchController#build_preview_projection used pluck(:action_type).to_set — showed all actions of an approved type as changed in preview, not just the approved (type, target_id) pairs (FIXED)
type: project
---

`AgentWorkbenchController#build_preview_projection` checked:
```ruby
approved_types = approved_approvals.pluck(:action_type).to_set
next unless approved_types.include?(action_type)
```

This is the same coarse-approval bug that was fixed in `ApplyApprovedMenuChangesJob` (see `pattern_apply_approved_changes_coarse_approval.md`). If the manager approved one `item_rename`, the preview would incorrectly show ALL `item_rename` actions as applied — including ones the manager rejected.

**Why:** The preview was written after the apply job bug was fixed, and the same incorrect pattern was used again. Preview is read-only (no DB writes) so this was a P2 misleading-UI bug, not P1 data corruption.

**How to apply:** Any loop over `all_actions` that checks approval status must use `(action_type, target_id)` pair matching, not just `action_type`. The pair is built from `pluck(:action_type, :proposed_payload).to_set { |at, pp| [at, pp['target_id']&.to_i] }`.
