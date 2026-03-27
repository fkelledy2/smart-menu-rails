---
name: CRM v1 deferred scope items
description: Items explicitly deferred from CRM Sales Funnel v1 to v2 during spec writing (2026-03-27)
type: project
---

The following were explicitly placed out of scope for CRM v1 and should not be added to the v1 implementation checklist:

- Public-facing lead capture forms (leads created manually or via webhook only)
- Email inbox / two-way email threading (ActionMailbox-based inbound parsing)
- Automated email sequences / drip campaigns
- Mobile native app view
- Lead scoring or ML-based prioritisation
- Integration with HubSpot, Salesforce, or other external CRMs
- Revenue forecasting / pipeline value reporting
- Contact deduplication engine
- Bulk CSV import of leads
- Multi-user realtime Kanban sync (ActionCable) — single-user view is sufficient for v1
- Reply tracking for outbound emails

**Why:** Scope control. The v1 goal is a functional internal pipeline tracker that unblocks the sales team. The above items add significant complexity with low immediate ROI.

**How to apply:** If a future conversation extends the CRM spec, check this list before adding scope to confirm whether the item was already considered and deferred.
