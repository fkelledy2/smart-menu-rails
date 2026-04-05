---
name: India Market Expansion — Deferred v2 Items
description: Items consistently scoped out of India Phase 0-2 that should be flagged as out-of-scope in any follow-on India spec
type: project
---

The following items were explicitly deferred from the India market expansion v1 spec (37-india-market-expansion.md):

- HSN/SAC code assignment per menu item (GST compliance depth)
- GSTIN validation via government API (stored as free-text initially)
- Tamil / Kannada / Telugu locales (Hindi-first for v1)
- Full modifier/add-on system (spice level is a simple integer; full modifier spec is separate)
- Zomato / Swiggy delivery integration (positioning is in-venue only)
- POS integrations
- AWS Mumbai / Heroku Private Spaces migration (Phase 3 infra, separate spec)
- Additional India payment providers: PhonePe Business, Paytm for Business
- Native Android/iOS app
- Staff tip distribution for India

**Why:** Phase 0-2 prioritises the minimum viable in-venue ordering + UPI payment loop. Compliance depth (HSN/SAC, GSTIN API) deferred to avoid blocking launch.

**How to apply:** When a user requests an India follow-on feature, check this list first — if it's here, note it was explicitly deferred and confirm whether scope has changed.
