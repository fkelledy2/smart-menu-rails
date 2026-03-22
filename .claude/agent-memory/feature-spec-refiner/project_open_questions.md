---
name: mellow.menu backlog open questions requiring stakeholder input
description: Open questions identified during spec refinement that require product or stakeholder decisions before features can be built
type: project
---

Open questions identified during the March 2026 full backlog refinement pass.

**Why:** These questions were identified during spec writing and cannot be assumed away by engineering. They need product/business decisions.

**How to apply:** Before scheduling any feature for sprint, ensure its open questions are resolved. Unresolved questions = incomplete spec = blocked developer.

## Launch Blockers

### QR Security (#1)
- Is payment-gating (Phase 1.4) a launch blocker or post-launch? Recommended: opt-in post-launch for pay-at-end restaurants.
- What is the UX when a dining session expires mid-meal?
- Should proximity codes (Phase 2.1) be tied to a specific plan tier?

### Branded Email (#2)
- Are brand assets (logo PNG, colour palette hex values) finalised and in app/assets/images/?
- Is there an existing UserMailer or should one be created?

### Branded Receipt Email (#3)
- Which field on Ordr stores last 4 digits / payment method from Stripe?
- Does the Restaurant model have a logo_url or ActiveStorage attachment?
- Is Twilio already integrated or is a new provider needed?
- Should the self-service receipt form appear before or after payment confirmation in SmartMenu?

## Launch Enhancers

### Auto Pay & Leave (#4)
- Auth+capture vs immediate capture — which model does the restaurant prefer?
- When should the order auto-close vs requiring kitchen sign-off?
- How should "Charge Now" manual capture work when no PaymentIntent has been created yet?

### Floorplan Dashboard (#5)
- Is Tablesetting the canonical table model, or is a new Table model planned?
- Can there be multiple active orders per table simultaneously?
- Should staff be able to perform actions from the tile in v1 or view-only?

## Post-Launch Features

### Menu Experiments (#10)
- Should experiments be limited to specific plan tiers (e.g. Pro/Business)? Recommend Pro and above.
- What analytics are shown to the restaurant owner? Minimum: exposure count + order count per variant.
- Should `allocation_pct` be editable on an in-progress experiment? Recommend: locked once active.

### Dynamic Pricing (#12, #13, #14)
- What is the plan weight/allocation model for distributing costs across plan tiers?
- Should annual billing use a fixed discount or be computed independently?
- How are existing customers backfilled into a "legacy" pricing model record?
- Which API is authoritative for subscriptions — Userplan only, or also RestaurantSubscription?

### MCP AI Agent (#15)
- Is there a suitable Ruby MCP gem or does this require a custom implementation?
- What is the GDPR/legal position on AI agents acting on behalf of restaurant owners? Requires legal review.

## Resolved Questions

### MenuVersion System — RESOLVED 2026-03-22
- Previous question: "When will the MenuVersion system be built? This is a hard dependency with no workaround."
- Resolution: System is fully built. `app/models/menu_version.rb`, four services, controller, DB schema, and tests all exist. No new build required. Reference spec at `docs/features/todo/features/menu-enhancements/menu-versioning-system.md`.
- Impact: Menu Experiments elevated from #14 to #10 in priority order.
