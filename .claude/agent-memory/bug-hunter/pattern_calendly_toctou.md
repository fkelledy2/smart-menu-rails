---
name: CalendlyEventHandler TOCTOU idempotency race condition
description: Idempotency check uses CrmLead.exists? then CrmLead.find_by — two separate queries with a window for concurrent Sidekiq retries to both pass the exists? check and proceed to create a duplicate lead
type: feedback
---

`Crm::CalendlyEventHandler#call` checks idempotency as:

```ruby
if event_uuid.present? && CrmLead.exists?(calendly_event_uuid: event_uuid)
  existing = CrmLead.find_by(calendly_event_uuid: event_uuid)
  return Result.new(success?: true, ...)
end
```

Two queries. If two Sidekiq workers retry the same webhook concurrently, both can pass the `exists?` check before either writes the UUID, then both proceed to `find_or_create_lead` and attempt to call `lead.update!(calendly_event_uuid: event_uuid)`. The unique partial index on `calendly_event_uuid` will rescue this with a `RecordNotUnique` exception, but it will raise an unhandled error on the second worker rather than silently deduplicating.

**Why:** The `exists?` + `find_by` pattern is idiomatic for single-process scenarios but is not safe under concurrent workers.

**How to apply:** Replace the two-query check with a single `find_by` and return early on non-nil. The unique index is the true safety net; ensure the `RecordNotUnique` exception is caught and treated as a successful idempotent return, not an error.
