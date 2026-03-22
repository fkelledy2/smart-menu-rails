# mellow.menu Feature Backlog — Priority Index

**Last updated**: 2026-03-22 (revised: MenuVersion system confirmed as fully built; Menu Experiments elevated)
**Guiding principle**: Every decision is filtered through one question — does this get mellow.menu in front of paying customers faster?

---

## Master Ranked Feature Table

| Rank | Feature | Category | Effort | Key Dependency | Rationale |
|------|---------|----------|--------|----------------|-----------|
| #1 | QR Code Security | Launch Blocker | M | None | Fraudulent remote orders are an existential risk to restaurant trust at launch |
| #2 | Branded Email Styling | Launch Blocker | S | None | Unbranded auth emails make the platform look unfinished; blocks trust |
| #3 | Branded Receipt Email | Launch Blocker | M | #2, Stripe/Ordr | Legal and UX requirement; restaurants cannot replace POS without receipts |
| #4 | Auto Pay & Leave | Launch Enhancer | L | #1, #3, Stripe | Closes the payment loop; key differentiator vs basic digital menu tools |
| #5 | Floorplan Dashboard | Launch Enhancer | M | Existing Tablesetting/Ordr | Single-glance ops view; staff adoption driver; differentiates from competitors |
| #6 | Pre-Configured Marketing QRs | Launch Enhancer | M | #1 (token infra) | Decouples print production from menu deployment; unblocks restaurant onboarding |
| #7 | Homepage Demo Booking & Video | Launch Enhancer | S | None | Minimum viable sales funnel; converts marketing traffic into bookable leads |
| #8 | JWT Token Management (API) | Post-Launch | L | Existing admin auth | Enterprise and integration-partner access; revenue unlock for larger groups |
| #9 | Partner Integrations (Event-Driven) | Post-Launch | M | #8, Stripe webhooks | Ecosystem play; required by workforce/CRM partners |
| #10 | Menu Experiments (A/B Testing) | Post-Launch | M | #1 (DiningSession); MenuVersion BUILT | Elevated from #14: MenuVersion dependency resolved — only needs QR Security (#1) to ship first |
| #11 | Table Wait Time Estimation | Post-Launch | L | #5, Tablesetting | Operations win; differentiates for high-footfall walk-in restaurants |
| #12 | Dynamic Pricing Plans (Cost-Indexed) | Post-Launch | L | #13, #14 | Sustainable margin management at scale |
| #13 | Cost Insights + Pricing Model Publisher | Post-Launch | L | #14 | Admin system enabling #12; required before pricing models can be published |
| #14 | Heroku Cost Inventory | Post-Launch | S | Admin auth, HEROKU_PLATFORM_API_TOKEN | Feeds #13 with accurate infra cost data |
| #15 | MCP AI Agent Wrapper | Post-Launch | XL | #8, legal review | Future platform play; not revenue-critical at launch |
| #16 | CDN Evaluation / Implementation | Post-Launch | S | Measured TTFB > 500ms | Deferred — revisit at traffic scale triggers |
| #17+ | R&D Initiatives (Floor OS) | R&D | Various | Core product stable | Strategic vision; not sprint work until launch blockers ship |

> **Note on re-ranking**: Heroku Cost Inventory (#14), Cost Insights (#13), and Dynamic Pricing (#12) have been renumbered from their previous #13/#12/#11 positions following the Menu Experiments elevation to #10. The relative order within the group is unchanged.

---

## Resolved Gap: MenuVersion System

**Previous status**: Flagged as "unbuilt hard dependency" blocking Menu Experiments.

**Current status**: Fully built and in production schema. The following exists in the codebase:
- `app/models/menu_version.rb` — immutable snapshot model with `create_from_menu!` class method
- `app/services/menu_version_snapshot_service.rb` — produces `snapshot_json` from live Menu
- `app/services/menu_version_diff_service.rb` — diffs two versions (sections + items)
- `app/services/menu_version_activation_service.rb` — activates a version (immediate or windowed)
- `app/services/menu_version_apply_service.rb` — projects snapshot back onto live AR objects
- `app/controllers/menus/versions_controller.rb` — list, diff, create, activate endpoints
- `db/schema.rb` — `menu_versions` table with all required columns and indexes
- `spec/` and `test/` — comprehensive test coverage

A reference specification documenting the as-built system is at: `docs/features/todo/features/menu-enhancements/menu-versioning-system.md`

---

## Launch Milestone — Minimum Viable Feature Set

The following features must ship before mellow.menu can accept live orders from paying restaurant customers:

| Rank | Feature | Why it's a Launch Blocker |
|------|---------|-----------------------------|
| #1 | QR Code Security | Without session binding and rotating tokens, fraudulent remote orders can reach kitchens |
| #2 | Branded Email Styling | Platform looks unprofessional without branded auth/onboarding emails |
| #3 | Branded Receipt Email | Restaurants legally require receipts; customers expect digital proof of payment |

Note: The launch blockers are deliberately narrow. Features #4–#7 are strong launch enhancers that meaningfully improve the product but are not strictly required to go live with ordering enabled.

---

## Sprint 1 Recommendation — Immediate Next Best Actions

Start these in parallel or sequential order based on team capacity:

### Track A: Security Foundation (Unblocks everything)
**Feature #1 — QR Code Security, Phase 1**

Deliverables in priority order:
1. Migration: `add_public_token_to_smartmenus` — backfill existing rows
2. Update QR generation to use `/t/:public_token` URL
3. Create `DiningSession` model + migration
4. Add `require_valid_dining_session!` before_action to order mutation endpoints
5. `ExpireDiningSessionsJob` (every 5 min via Sidekiq cron)
6. Rack::Attack order-specific throttles
7. Admin "Regenerate QR" button on table settings

Estimated: 2–3 developer weeks

### Track B: Brand & Trust (Can run in parallel with Track A)
**Feature #2 — Branded Email Styling**

Deliverables:
1. Update `app/views/layouts/mailer.html.erb` with branded header/footer
2. Inline CSS (or use a CSS inliner gem like `premailer-rails`)
3. Update all Devise mailer views to use branded layout
4. Create `UserMailer#welcome_email` if not already present
5. Test all 5 critical email types in ActionMailer previews

Estimated: 3–5 developer days

### Track C: Payment Closure (Depends on Track A session model)
**Feature #3 — Branded Receipt Email, after #2 branded layout is done**

Deliverables:
1. `create_receipt_deliveries` migration
2. `ReceiptMailer#customer_receipt` using branded layout
3. `ReceiptDeliveryJob` with retry logic
4. Staff UI: "Email Receipt" button on paid orders
5. Customer self-service receipt form on SmartMenu

Estimated: 1–2 developer weeks

---

## Dependencies Graph

```
#1 QR Security
  └─► #4 Auto Pay & Leave (needs DiningSession)
  └─► #6 Pre-Configured Marketing QRs (needs token infrastructure)
  └─► #10 Menu Experiments (needs DiningSession for assignment storage)

#2 Branded Email Styling
  └─► #3 Branded Receipt Email (needs branded layout)
  └─► #7 Homepage Demo Booking (uses branded mailer)

#3 Branded Receipt Email
  └─► #4 Auto Pay & Leave (sends receipt on successful capture)

#5 Floorplan Dashboard
  └─► #11 Table Wait Time Estimation (shares table state model)

#8 JWT Token Management
  └─► #9 Partner Integrations (needs JWT auth for API endpoints)
  └─► #15 MCP AI Agent Wrapper (needs JWT for agent API access)

#13 Cost Insights + Pricing Publisher
  └─► #12 Dynamic Pricing Plans (needs cost data to compute prices)

#14 Heroku Cost Inventory
  └─► #13 Cost Insights (feeds infra cost data)

MenuVersion System (BUILT — no action required)
  └─► #10 Menu Experiments (dependency satisfied)
```

---

## Feature Category Definitions

| Category | Definition |
|----------|-----------||
| **Launch Blocker** | Platform cannot acceptably go live without this. Blocks the first paying restaurant. |
| **Launch Enhancer** | Materially improves the launch product or first-sale experience. High value, not strictly blocking. |
| **Post-Launch** | Important for growth, retention, or operations, but not required for the first live restaurant. |
| **Already Shipped** | System is fully built and in production. Documented for reference only. |
| **R&D** | Strategic research bets. Not sprint-ready. Require further scoping before entering the backlog. |

---

## Effort Scale

| Label | Typical Scope |
|-------|--------------|
| S | 1–5 developer days |
| M | 1–2 developer weeks |
| L | 3–6 developer weeks |
| XL | 7+ developer weeks |

---

## Features Not In Priority Table (R&D — Not Sprint-Ready)

The following R&D initiatives are documented in `r_and_d/` and are strategic bets rather than ready-to-build features. They should not enter the sprint backlog until the launch-blocker and launch-enhancer features are shipped. See `r_and_d/README.md` for their recommended build sequence.

**Currently Feasible (highest priority within R&D horizon):**
- Table Digital Twin & State Machine Layer — foundational for most R&D epics
- Ultra-Low Latency Menu Runtime — benefits the entire product
- Recommendation & Taste Graph — revenue-enhancing, data compounds with scale
- Context-Aware Adaptive Menus — strong differentiation
- Social Dining Intelligence — conversion lift
- Staff Assistance & Proximity Response — operational value
- Presence, Identity & Return-Guest Warm Start — retention
- Conversational & Voice Ordering — accessibility + differentiation
- Distributed Restaurant Operating Surface — platform unification

**Smart Table Entry Points (NFC)** — closely related to QR Security (#1). Can be scoped as a fast-follow enhancement once Phase 1 QR security ships. Relatively low R&D risk.

**Partially Feasible / R&D Horizon 2:**
- Proximity-Aware Table Context
- Collaborative Dining Mesh
- Personal AI Dining Assistant
- Kitchen-Aware Commercial Optimization
- Ambient Sensing & Restaurant State Detection
- Cross-Table Social & Commerce Layer
- Edge Intelligence & Resilient Local Compute

**Requires External Tech Advancement (Horizon 3):**
- UWB Table Detection
- Browser-Native Local Mesh Networking
- Nearby Menu Propagation

**Deprioritised:**
- Crowd-Sourced Menu Media Graph (nah/) — requires moderation infrastructure; post-launch
- Interactive Dining Entertainment Layer (nah/) — venue-type-specific; post-launch
- Camera-Driven Recognition & Reorder Flows (nah/) — high complexity, low breadth; post-launch

---

## Gap Analysis — Features Implied But Not Yet Specified

The following requirements are implied by existing specs but do not yet have standalone feature files. They should be created before their dependent features enter development:

| Implied Feature | Implied By | Urgency | Status |
|----------------|-----------|---------| -------|
| MenuVersion System | Menu Experiments (#10) | High — hard dependency | RESOLVED — fully built; see `menu-versioning-system.md` |
| Bill Splitting (referenced in Auto Pay) | Auto Pay & Leave (#4) | Post-launch | Open |
| Twilio / SMS provider integration | Receipt Email (#3), Wait Time (#11) | Post-launch stretch | Open |
| Ordr state machine documentation | Auto Pay (#4), Floorplan (#5) | Pre-development clarification | Open |
| Restaurant onboarding checklist / progress tracking | Branded Email (#2) | Post-launch | Open |

---

## Key Architectural Decisions Made During Prioritisation

1. **QR Security before Auto Pay**: A `DiningSession` is a prerequisite for safe payment method capture. Security cannot be retrofitted after payment flows are live.
2. **Branded emails before receipts**: The receipt mailer inherits the branded layout. Building them in sequence avoids rework.
3. **Admin JWT before Partner Integrations**: Partner API endpoints require the JWT authentication layer that #8 provides.
4. **Heroku Inventory before Cost Publisher before Dynamic Pricing**: These three form a strict dependency chain. They cannot be built in parallel.
5. **MenuVersion system is fully built**: Confirmed via codebase inspection — `app/models/menu_version.rb`, four services, controller, DB schema, and tests all exist. Menu Experiments (#10) only needs QR Security (#1) to ship first, not a new MenuVersion build.
6. **R&D items explicitly excluded from sprint capacity** until launch blockers (#1, #2, #3) and at least two launch enhancers (#4, #5) are shipped.
7. **Payments always via Orchestrator**: No direct Stripe/Square calls in any new feature. All payment flows route through `Payments::Orchestrator`.
8. **Admin cost tooling in `Admin::` namespace, never Madmin**: Confirmed across #12 and #13 specs.
