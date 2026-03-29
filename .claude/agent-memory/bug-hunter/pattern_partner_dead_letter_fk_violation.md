---
name: PartnerIntegrationDispatchJob dead-letter writes restaurant_id=0 which violates FK constraint
description: record_dead_letter falls back to restaurant_id: 0, but partner_integration_error_logs has a FK on restaurants — dead-letter record is silently lost
type: feedback
---

`PartnerIntegrationDispatchJob#record_dead_letter` at line 65 writes `restaurant_id: @restaurant_id || 0`. When `@restaurant_id` is nil (e.g. the job failed before instance vars were set), it writes `0`. The `partner_integration_error_logs` table has a foreign key constraint on `restaurants(id)`. Restaurant id 0 does not exist, so the insert fails with a PG FK violation, which is caught by the outer `rescue StandardError` at line 72 and logged but not surfaced.

**Why:** The job sets `@restaurant_id = restaurant_id` (the raw argument) at line 36. If the job never reaches that line (e.g. early return at line 21-28 doesn't raise, so dead letter never fires), this is safe. But if the job raises between lines 0-35, the vars are nil and the dead letter write silently fails.

**How to apply:** In `record_dead_letter`, use `restaurant_id: @restaurant_id.presence&.to_i` and only write the record if `@restaurant_id` is present. Or make the `restaurant_id` column nullable in the table.
