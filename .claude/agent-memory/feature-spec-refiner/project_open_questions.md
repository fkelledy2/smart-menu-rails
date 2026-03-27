---
name: mellow.menu backlog open questions requiring stakeholder input
description: Open questions identified during spec refinement that require product or stakeholder decisions before features can be built — updated to include AI agent tier questions
type: project
---

Open questions identified during the March 2026 full backlog refinement pass (initial pass 2026-03-22; AI agent tier added 2026-03-24; rank corrections applied 2026-03-27 after CRM inserted at #9).

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

## AI Agent Tier Pre-Development Gates (NEW — 2026-03-24)

### Agent Framework (#15) — blocks all agent work
- **LLM provider strategy**: OpenAI-only in v1, or build a provider-agnostic adapter from the start? Recommendation: OpenAI-only with an abstraction layer that can be swapped later. Decision required before schema design.
- **AgentPolicy self-service**: Can restaurant owners modify auto-approve/escalate policies from a self-service UI in v1, or is this admin-managed? Affects back-office UI scope estimate significantly.
- **Audit log retention period**: ToolInvocationLog and AgentWorkflowRun records — how long are they retained? Recommendation: 90 days then archive. Legal/compliance input needed before migration is written.
- **PgBouncer in production**: Is PgBouncer transaction pooling active? If yes, LISTEN/NOTIFY cannot be used for domain event dispatch — the polling approach (Sidekiq cron polls agent_domain_events table) is required. Confirm before building Agents::Dispatcher.

### Customer Concierge Agent (#18) — HARD BLOCKER
- **GDPR / AI processing DPA**: Passing customer dietary preference data and query text to OpenAI's API is a customer-facing data processing activity. This must be covered by mellow.menu's DPA with OpenAI and disclosed in the platform privacy policy. Requires legal review before #18 enters development. This is non-negotiable.
- **Logging raw query text**: Should the concierge log the customer's raw query text in AgentWorkflowRun.context_snapshot? Recommendation: log only structured output (item IDs, add-to-cart count) not raw queries. Needs legal/product confirmation.
- **Entry point UX**: FAB (floating action button) vs inline prompt bar? FAB risks covering menu content on mobile. Needs UX decision and mobile testing.

### Reputation & Feedback Agent (#21)
- **Review platform ingestion**: Does the platform currently receive Google/TripAdvisor reviews via API? If not, `review.received` events are limited to in-app checkout ratings only in v1. Needs product confirmation.
- **Discount/promo code system**: Does a discount code generation system exist? Without it, the "offer discount" recovery action is advisory text only and cannot issue a redeemable code.
- **Abandoned payment detection**: Which field on Ordr tracks payment status? Confirm the correct field/enum value for "payment pending" to drive DetectAbandonedPaymentsJob.
- **Customer identity for recovery messages**: Is there a per-customer email capture at checkout? Without it, recovery messages cannot be sent. Confirm whether email capture at checkout is implemented.

### Staff Copilot (#22)
- **Waiter access scope**: Should waiters have access to the copilot, or is it manager/owner only? Spec assumes limited waiter access (availability flags only, not menu edits). Confirm the role boundary.
- **Ambiguous item name disambiguation**: How should the copilot handle "86 the chicken" when multiple chicken dishes exist? Confirm that a disambiguation card interaction pattern is acceptable.
- **Confirm endpoint design**: Separate `/copilot/confirm` endpoint vs re-submitting with `confirmed: true` flag. Separate endpoint is cleaner for audit — decision needed.
- **Internal messaging system**: Does an existing staff briefing / internal messaging system exist that `draft_staff_message` should integrate with?

### Menu Optimization Agent (#19)
- **Existing menu_optimization_service.rb**: Does this service exist and does it cover item-level performance tagging? Confirm before building Step 1 data aggregation logic.
- **Time-gated suppression in v1**: Should `item_suppress` support time-gated availability (e.g. "hide after 20:00")? Requires a scheduled job for toggling. Confirm engineering capacity before including in v1 scope.

### Restaurant Growth Agent (#17) / Menu Optimization Agent (#19)
- **Minimum data threshold**: 5 orders in 7 days — is this the right threshold for Growth Digest? 14 days for Menu Optimization? Product validation needed to avoid empty or low-quality digests for new restaurants.

## New Post-Launch Product Features (added 2026-03-24 second pass)

### Two-Factor Authentication (#26)
- **Enforcement scope**: Should `two_factor_enforcement` Flipper flag require 2FA for `manager` role as well as `admin`, or admin-only? Spec assumes admin-only in v1 — confirm.
- **OTP lockout duration**: Spec assumes 15 minutes after 5 failed attempts. Confirm acceptable lockout duration with product.
- **Trusted device window**: 30-day trusted-device cookie — is this an acceptable security/convenience tradeoff? Some customers may prefer shorter (7 days).

### Employee Role Promotion (#27)
- **Demotion confirmation**: Should demotion (e.g. admin → staff) require a separate two-step confirmation modal given severity? Recommend yes — confirm with product.
- **`changed_by` reference scope**: Should `EmployeeRoleAudit#changed_by` reference the `Employee` record or the `User` record? Spec recommends `Employee` (restaurant-scoped) — confirm.
- **EmployeePolicy context**: Does the existing `EmployeePolicy` already have a `current_employee_for_restaurant` helper pattern, or does it rely on `current_user`? Confirm before writing the service.

### Bulk Employee Invitation (#28)
- **Plan tier gating**: Should bulk invite be restricted to Pro+ plan tier, or gated solely by Flipper in v1? Confirm.
- **Maximum batch size**: Spec assumes 500 rows. Confirm with infra.
- **Manager bulk invites**: Can managers bulk-invite other managers? Or should admin-only be required for manager-tier invites in bulk batches?

### Weight-Based Pricing (#29)
- **Plan tier gating**: Should weight-based pricing require a specific plan tier (e.g. Pro+)? Confirm.
- **Weight units**: Grams-based only in v1 (`50g`, `100g`, `1kg`)? Or should ounces/pounds be supported for non-metric markets?
- **`calculated_price` column on Ordritem**: Confirm exact column name in the DB schema before writing the migration. Check if it's `calculated_price`, `unit_price`, or computed differently.

### Nearby Menus Map (#30)
- **PostGIS availability**: Is PostGIS enabled in production? Determines whether spatial queries use `ST_DWithin` or a bounding-box approximation. MUST confirm with infra before writing the service.
- **Map provider**: Mapbox or Google Maps? Does an existing Google Maps API key exist in the project?
- **SSR for SEO**: Should the `/discover` page include server-side rendered restaurant cards for search engine indexing? Requires Hotwire initial-page render with restaurant data embedded, not purely JS-rendered markers.
- **Network size at launch**: How many restaurants will be geocoded at launch? Affects caching strategy and whether the 100-result bounding-box cap is appropriate.

### Strikepay Integration (#31)
- **HARD GATE — Platform API model**: Does Strikepay offer a marketplace/platform mode where mellow.menu is the platform? Or does each staff member need a standalone Strikepay account? This determines the entire auth architecture. DO NOT begin development until confirmed with Strikepay BD.
- **Supported markets**: Which countries is Strikepay operational in? Feature should only be offered to restaurants in those markets.
- **Tip income reporting obligation**: Is mellow.menu responsible for any tax reporting on tips, or does Strikepay handle this entirely? Legal/compliance confirmation required.
- **Webhook reliability**: Does Strikepay offer retry guarantees for webhook delivery?

## Resolved Questions

### MenuVersion System — RESOLVED 2026-03-22
- Previous question: "When will the MenuVersion system be built? This is a hard dependency with no workaround."
- Resolution: System is fully built. `app/models/menu_version.rb`, four services, controller, DB schema, and tests all exist. No new build required. Reference spec at `docs/features/todo/features/menu-enhancements/menu-versioning-system.md`.
- Impact: Menu Experiments elevated from #14 to #10 in priority order.

### MCP AI Agent Wrapper dependency — RESOLVED 2026-03-24
- Previous question: Is MCP Agent Wrapper a standalone feature or does it depend on the internal agent framework?
- Resolution: MCP Wrapper depends on both JWT (#8) and Agent Framework (#15). It exposes the same toolbox used internally. Building MCP before the internal toolbox is proven would create an unstable public API. Renumbered from #15 to #23.
