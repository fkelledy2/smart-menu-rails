---
name: India Table Mode Architecture Decision
description: How shared table sessions work — group_token on DiningSession, table_group_id on Ordr, no structural change to Ordrparticipant
type: project
---

India Table Mode (shared group ordering) adds `group_token varchar(64)` to `dining_sessions` and `table_group_id bigint` to `ordrs` (FK to `ordrs.id`). Multiple `DiningSession` records share a group token; their associated `Ordr` records link to one primary ordr via `table_group_id`. The existing `Ordrparticipant` / `OdrSplitPayment` model is reused for final bill settlement — no structural changes needed.

**Why:** Keeps separate auditable `Ordr` records per participant (compatible with existing split logic) while enabling a consolidated bill view. Avoids merging ordrs into a single record which would conflict with existing `Ordrparticipant` assumptions.

**How to apply:** When speccing any India multi-user table feature, use the `group_token` → `table_group_id` linkage pattern, not a new join model.
