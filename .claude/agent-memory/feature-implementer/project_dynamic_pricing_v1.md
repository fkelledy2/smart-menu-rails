---
name: Dynamic Pricing Plans v1 (#14)
description: Cost-indexed pricing infrastructure, PricingRecorder service, Flipper-gated checkout integration, billing page version display, admin override (April 2026)
type: project
---

Feature #14 COMPLETED 2026-04-05.

The core infrastructure (models, migrations, services, admin UI, policy) was already built as part of #15 Cost Insights. What was missing and was added:

1. `Pricing::PricingRecorder` service — records pricing snapshot (model, price, currency, interval, stripe_price_id) onto Userplan after signup or plan change
2. `Payments::SubscriptionsController#start` — wired `cost_indexed_pricing` Flipper flag; `resolve_stripe_price_id` helper uses model's stripe_price_id when flag is on
3. `UserplansController#stripe_success` — calls PricingRecorder after checkout completes; interval/currency extracted from session metadata
4. `UserplansController#portal_plan_changed` — calls PricingRecorder after portal plan change; matches cost-indexed stripe_price_ids as valid expected IDs
5. `UserplansController#start_plan_change` — resolves price via `resolve_stripe_price_id` (flag-gated)
6. `Admin::UserplansController` — new controller; `pricing_override` POST action for super_admin to change plan while keeping original cohort pricing
7. `UserplanPolicy#pricing_override?` — super_admin-only gate
8. Billing page (`userplans/edit.html.erb`) — shows "Your pricing version: X — Price locked since signup — EUR X.XX/month" panel when `price_locked?` is true
9. Admin pricing model show — new "Customers on this Pricing Version" table with inline override form

**Why:** Ensures new signups reflect current running costs; existing customers never repriced. Price locked at signup date.

**How to apply:** The `cost_indexed_pricing` Flipper flag must be enabled in production after at least one pricing model is published. Run `Pricing::LegacyBackfillService.run` before enabling to backfill existing customers.

**Key gotcha:** `redirect_back_or_to path, alert: 'msg'` — do NOT use `redirect_back_or_to(path), alert:` syntax (comma creates a syntax error — Ruby reads it as a second argument to a non-existent method).
