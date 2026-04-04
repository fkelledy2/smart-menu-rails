---
name: ApplyApprovedMenuChangesJob coarse-grained approval check applies unapproved actions
description: approved_action_types is a set of type strings — if any item_rename is approved, ALL item_rename actions in the change set are applied including rejected ones
type: project
---

`ApplyApprovedMenuChangesJob#apply_artifact` (lines 59-66) checks:
```ruby
approved_action_types = run.agent_approvals.where(status: 'approved').pluck(:action_type).uniq
next unless approved_action_types.include?(action_type)
```

This is too coarse. If there are 3 `item_rename` approvals and only 1 is approved, all 3 items get renamed. The check needs to match by `target_id` (via `proposed_payload['target_id']`), not just by action type.

**Why:** The artifact `content['actions']` contains multiple actions of the same type targeting different items. The approval records store `target_id` inside `proposed_payload`. The apply loop must cross-reference `action['target_id']` against approved approval `proposed_payload['target_id']`.

**How to apply:** When reviewing menu optimization apply logic, verify the granularity of approval matching.
