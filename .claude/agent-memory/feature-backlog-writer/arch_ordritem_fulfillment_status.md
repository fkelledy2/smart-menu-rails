---
name: Ordritem fulfillment_status is separate from status
description: The Ordritem model has an existing status enum (opened/ordered/paid etc.) — new kitchen/bar tracking uses a separate fulfillment_status column, not a replacement
type: feedback
---

The `ordritems.status` column tracks the commercial lifecycle (`opened: 0, removed: 10, ordered: 20, preparing: 22, ready: 24, delivered: 25, billrequested: 30, paid: 35, closed: 40`). Do not modify or replace this enum when adding fulfillment tracking.

A new `fulfillment_status` column (integer enum, `pending/preparing/ready/collected`) tracks kitchen/bar fulfillment state independently. Use `prefix: :fulfillment` on the enum declaration to prevent helper name collisions with the existing `status` enum.

**Why:** The existing `status` enum is deeply coupled to the order payment lifecycle and is referenced across channels, services, and jobs. Replacing it with a new 4-value enum would be a breaking change across the codebase.

**How to apply:** Any future spec or implementation that adds state tracking to `Ordritem` must check both enums exist and avoid reusing the `status` column name for a different state machine.
