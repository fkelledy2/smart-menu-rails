---
name: DatabaseRoutingService.replica_lag runs on primary, always returns 0
description: replica_lag used on_primary — pg_last_xact_replay_timestamp() always NULL on primary, COALESCE returns 0, health check always passes (FIXED)
type: feedback
---

`DatabaseRoutingService.replica_lag` called `ApplicationRecord.on_primary` to run `pg_last_xact_replay_timestamp()`. That PG function only returns a non-NULL value on a streaming standby (replica). On the primary it always returns NULL, so `COALESCE(..., 0)` yields `0.0`, making `check_replica_health` always see lag < 5s and always return `true`.

**Why:** The query needs to run on the replica connection to get an actual lag measurement.

**How to apply:** Any call to `pg_last_xact_replay_timestamp()` must use `ApplicationRecord.on_replica`. Fixed by changing `on_primary` to `on_replica` in `app/services/database_routing_service.rb`.
