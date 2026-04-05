---
name: GST / Tax-Inclusive Pricing Architecture
description: GST is a Restaurant-level config (tax_inclusive flag + tax_rate_percentage); MenuItem price always stored as consumer-facing inclusive price
type: project
---

GST configuration lives on `Restaurant`: `tax_inclusive boolean`, `tax_rate_percentage decimal(5,2)`, `gstin varchar(15)`. MenuItem price columns are unchanged — when `tax_inclusive: true`, the stored price IS the GST-inclusive price. A `Payments::GstInvoiceBuilder` service computes the breakdown for receipt display (base amount, tax amount, total). No changes to `Ordr`/`Ordritem` price columns.

**Why:** Simplest migration path — existing price storage and checkout math are unaffected. India mandates prices displayed inclusive of GST; storing inclusive price as the single source of truth avoids dual-price complexity.

**How to apply:** Any feature touching Indian restaurant pricing must check `restaurant.tax_inclusive` and use `GstInvoiceBuilder` for display. Never recalculate tax from stored price outside that service.
