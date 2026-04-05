---
name: Contact form is email + message only; no name or restaurant name fields
description: ContactsController + Contact model only capture email and message — no name, restaurant, or phone; contact form → CRM ingestion is a separate spec (#27)
type: project
---

`Contact` model has only `email` (string) and `message` (text). `ContactsController` creates a `Contact` record and fires two mailers (receipt + notification). It does NOT create a `CrmLead`. Contact form → CRM ingestion is planned under spec #27 (Lead Source Tracking + Website Inbound Lead Ingestion).

There is no `name` or `restaurant_name` field on the contact form as of 2026-04-04.

**Why:** Relevant when speccing any feature that touches inbound lead capture from the contact form — the Contact record is thin; enrichment relies on email alone.

**How to apply:** When enrichment fires from a Contact-originated CrmLead, only email is available as enrichment input. Company/person name from enrichment API response may be the first time a name is associated with that lead.
