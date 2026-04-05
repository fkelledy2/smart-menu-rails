---
name: Reputation Dashboard N+1 Queries
description: AgentWorkbenchController#reputation fired one DB query per artifact for pending approvals and response rate (FIXED)
type: project
---

`AgentWorkbenchController#reputation` had two N+1 queries: (1) `a.agent_workflow_run.agent_approvals.pending.exists?` fired per artifact for `pending_response` stat; (2) `calculate_response_rate` fired per artifact for response rate. Fixed by pre-loading run IDs via set membership checks with single IN queries.

**Why:** Stats were aggregated in Ruby from an array of artifacts without pre-loading related approval counts.

**How to apply:** When aggregating stats over a collection that requires related-record counts, always pre-load with one query using `pluck.to_set` and check set membership in Ruby.
