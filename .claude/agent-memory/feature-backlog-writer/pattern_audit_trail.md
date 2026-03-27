---
name: Dedicated audit model preferred over paper_trail gem
description: Immutable field-change audit trails use a dedicated *Audit model, not the paper_trail gem
type: project
---

When a feature requires a full audit trail of field changes (who changed what, from what value, to what value), the established approach is a dedicated `*Audit` model rather than adding the `paper_trail` gem.

Structure of an audit model:
- `actor_id` (FK to users), `actor_type` ('user' | 'system')
- `event` (string enum: 'stage_changed', 'field_updated', 'email_sent', etc.)
- `field_name`, `from_value`, `to_value` (text, serialised)
- `metadata` (jsonb for arbitrary context)
- `created_at` only — no `updated_at`; records are immutable

All audit writes go through a single `*AuditWriter` service — never write audit records directly from models or controllers.

**Why:** Avoids adding a new gem (paper_trail) when a purpose-built model gives explicit control over what is captured, how it is queried, and ensures immutability. paper_trail was evaluated and rejected for this reason.

**How to apply:** Any future spec requiring an audit trail should follow this pattern. If a future spec re-proposes paper_trail, note this decision and recommend the dedicated model approach instead.
