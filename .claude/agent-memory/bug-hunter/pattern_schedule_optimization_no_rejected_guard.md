---
name: schedule_optimization bypasses artifact status — rejected artifacts re-approved without audit trail
description: AgentWorkbenchController#schedule_optimization set approved status on any non-applied artifact, including rejected ones, with no approved_by/approved_at set (FIXED)
type: project
---

`AgentWorkbenchController#schedule_optimization` called:

```ruby
@artifact.update!(status: 'approved', scheduled_apply_at: apply_at)
```

Two bugs:
1. No guard against `@artifact.rejected?` — a manager could accidentally schedule a rejected change set and re-approve it silently.
2. `approved_by` and `approved_at` were not set — the artifact showed `approved` with no audit of who approved it.

Fixed to check `@artifact.rejected? || @artifact.applied?` and redirect with an alert, plus pass `approved_by: current_user, approved_at: Time.current` in the update.

**Why:** The view showed the Schedule Rollout form for any artifact where `!applied? && scheduled_apply_at.blank?`, which includes rejected artifacts. The controller didn't enforce the same guard.

**How to apply:** Whenever transitioning artifact status in a controller, always (a) guard against invalid source states, (b) set audit fields (approved_by, approved_at) to maintain a complete trail.
