# mellow.menu Feature Backlog — Priority Index

**Last updated**: 2026-03-25 (Branded Receipt Email completed; Auto Pay & Leave is now #1 active launch enhancer)
**QR Code Security (#1)**: COMPLETED 2026-03-24 — Phase 1 shipped; spec at `docs/features/completed/qr-security.md`
**Branded Email Styling (#1)**: COMPLETED 2026-03-24 — spec at `docs/features/completed/branded-email-styling-feature-request.md`
**Branded Receipt Email (#2)**: COMPLETED 2026-03-25 — spec at `docs/features/completed/branded-receipt-email-feature-request.md`
**Guiding principle**: Every decision is filtered through one question — does this get mellow.menu in front of paying customers faster?

---

## Master Ranked Feature Table

| Rank | Feature | Category | Effort | Key Dependency | Rationale |
|------|---------|----------|--------|----------------|-----------|
| ~~#1~~ | ~~QR Code Security~~ | ~~Launch Blocker~~ | M | — | COMPLETED 2026-03-24 — Phase 1 shipped |
| ~~#1~~ | ~~Branded Email Styling~~ | ~~Launch Blocker~~ | S | — | COMPLETED 2026-03-24 — spec at `docs/features/completed/branded-email-styling-feature-request.md` |
| ~~#2~~ | ~~Branded Receipt Email~~ | ~~Launch Blocker~~ | M | Branded Email (#1 done), Stripe/Ordr | COMPLETED 2026-03-25 — spec at `docs/features/completed/branded-receipt-email-feature-request.md` |
| #4 | Auto Pay & Leave | Launch Enhancer | L | #1, #3, Stripe | Closes the payment loop; key differentiator vs basic digital menu tools |
| #5 | Floorplan Dashboard | Launch Enhancer | M | Existing Tablesetting/Ordr | Single-glance ops view; staff adoption driver; differentiates from competitors |
| #6 | Pre-Configured Marketing QRs | Launch Enhancer | M | #1 (token infra) | Decouples print production from menu deployment; unblocks restaurant onboarding |
| #7 | Homepage Demo Booking & Video | Launch Enhancer | S | None | Minimum viable sales funnel; converts marketing traffic into bookable leads |
| #8 | JWT Token Management (API) | Post-Launch | L | Existing admin auth | Enterprise and integration-partner access; revenue unlock for larger groups |
| #9 | Partner Integrations (Event-Driven) | Post-Launch | M | #8, Stripe webhooks | Ecosystem play; required by workforce/CRM partners |
| #10 | Menu Experiments (A/B Testing) | Post-Launch | M | #1 (DiningSession); MenuVersion BUILT | Elevated: MenuVersion dependency resolved — only needs QR Security (#1) to ship first |
| #11 | Table Wait Time Estimation | Post-Launch | L | #5, Tablesetting | Operations win; differentiates for high-footfall walk-in restaurants |
| #12 | Dynamic Pricing Plans (Cost-Indexed) | Post-Launch | L | #13, #14 | Sustainable margin management at scale |
| #13 | Cost Insights + Pricing Model Publisher | Post-Launch | L | #14 | Admin system enabling #12; required before pricing models can be published |
| #14 | Heroku Cost Inventory | Post-Launch | S | Admin auth, HEROKU_PLATFORM_API_TOKEN | Feeds #13 with accurate infra cost data |
| #15 | Agent Framework — Shared Infrastructure | Post-Launch | L | OpenAI API, Sidekiq, PostgreSQL | Foundation for all AI agent work; must ship before any individual agent |
| #16 | Menu Import Agent | Post-Launch | M | #15 Agent Framework | Highest-value onboarding accelerator; reduces time-to-first-menu from hours to minutes |
| #17 | Restaurant Growth Agent | Post-Launch | M | #15 Agent Framework, analytics services | Weekly digest turns raw data into actionable owner insights; low risk, clear ROI |
| #18 | Customer Concierge Agent | Post-Launch | M | #15 Agent Framework, SmartMenu view | Customer-facing differentiation; drives order value uplift via natural-language discovery |
| #19 | Menu Optimization Agent | Post-Launch | M | #15, #17 patterns, 14+ days order data | Structured change-set proposals; builds on Growth Digest patterns; drives conversion |
| #20 | Service Operations Agent | Post-Launch | M | #15, Kitchen/Station dashboards, ActionCable | Real-time ops intelligence; reduces kitchen congestion and service recovery lag |
| #21 | Reputation & Feedback Agent | Post-Launch | M | #15, in-app rating system, email mailers | Protects revenue by surfacing and recovering negative signals before they compound |
| #22 | Staff Copilot Agent | Post-Launch | L | #15, back-office service layer | NL interface to back office; biggest UX integration effort; ship after agent patterns proven |
| #23 | MCP AI Agent Wrapper | Post-Launch | XL | #8 JWT, #15 Agent Framework, legal review | External AI agent ecosystem play; not revenue-critical until agent tier is proven internally |
| #24 | CDN Evaluation / Implementation | Post-Launch | S | Measured TTFB > 500ms | Deferred — revisit at traffic scale triggers |
| #25+ | R&D Initiatives (Floor OS) | R&D | Various | Core product stable | Strategic vision; not sprint work until launch blockers ship |
| #26 | Two-Factor Authentication | Post-Launch | M | Devise (built), Redis (built) | Security hardening for accounts controlling payments; increasingly expected by enterprise customers |
| #27 | Employee Role Promotion | Post-Launch | S | Employee model (built), StaffInvitation (built) | Enables restaurant teams to grow organically without manual admin intervention; audit trail included |
| #28 | Bulk Employee Invitation | Post-Launch | M | StaffInvitation (built), Sidekiq (built) | Reduces onboarding friction for multi-staff restaurants; leverages existing invitation infrastructure |
| #29 | Weight-Based Menu Item Pricing | Post-Launch | M | Menuitem model, Ordritem model, KDS | Unlocks premium dining and butcher/seafood segments that require per-weight pricing |
| #30 | Nearby Menus Map | Post-Launch | L | Geocoding data, map provider API key | Consumer-facing discovery surface; organic acquisition channel for new restaurant sign-ups |
| #31 | Strikepay Integration (Staff Tipping) | Post-Launch | L | Payments::Orchestrator, Strikepay API agreement | Staff satisfaction and retention differentiator; compliance-heavy — Strikepay platform API confirmation required before build |

> **Note on March 2026 additions (first pass)**: Ranks #15–#22 are new AI agent features added in the 2026-03-24 pass. The MCP AI Agent Wrapper, previously #15, is renumbered to #23 as it now correctly depends on both the JWT system (#8) and the Agent Framework (#15). CDN Evaluation moves from #16 to #24 accordingly.

> **Note on March 2026 additions (second pass)**: Ranks #26–#31 are six new product specs (2FA, Employee Role Promotion, Bulk Employee Invite, Weight-Based Pricing, Nearby Menus Map, Strikepay Integration) refined from raw requirements added to the backlog on 2026-03-23. All are classified Post-Launch. Key architectural corrections applied during refinement: (1) Employee Role Promotion was re-scoped to target the `Employee` model's existing role enum — not the `User` model as the raw spec proposed; (2) Bulk Employee Invite was designed to extend the existing `StaffInvitation` model rather than replace it; (3) Nearby Menus Map had React components replaced with Stimulus/Hotwire pattern; (4) Strikepay Integration had direct API calls replaced with `Payments::Orchestrator` / `Payments::StrikepayAdapter` pattern, and a hard pre-development gate added pending Strikepay platform API confirmation. Nine marketing/analysis documents were also classified and dispositioned (not dev specs; no new engineering tickets derived).

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
| ~~#1~~ | ~~QR Code Security~~ | COMPLETED 2026-03-24 |
| ~~#2~~ | ~~Branded Email Styling~~ | COMPLETED 2026-03-24 |
| ~~#3~~ | ~~Branded Receipt Email~~ | COMPLETED 2026-03-25 |

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

## AI Agent Tier — Build Sequence

The AI agent features (#15–#22) form a coherent product tier that should be built as a sequential programme after the launch blockers and at least two launch enhancers (#4 and #5) have shipped. The internal build sequence is strict:

### Phase 0: Agent Framework (#15) — prerequisite for all agents
Build the shared infrastructure: workflow models, runner, toolbox, policy evaluator, artifact writer, approval router, Sidekiq queues, and the AI Workbench UI. Estimated: 4–6 developer weeks.

### Phase 1: First Agents (can overlap; both build on the same toolbox)
- **#16 Menu Import Agent** — highest onboarding value; extends existing OCR pipeline
- **#17 Restaurant Growth Agent** — lowest risk first agent; read-only plus advisory
- **#18 Customer Concierge Agent** — customer-facing differentiation; requires streaming LLM responses

Ship Phase 1 agents once the framework is stable (at least one full run through the approval workflow in production). Estimated: 2–3 developer weeks per agent.

### Phase 2: Operational Agents (ship in any order after Phase 1 is live)
- **#19 Menu Optimization Agent** — extends Growth Digest with executable change sets
- **#20 Service Operations Agent** — live order-flow intelligence; highest latency sensitivity
- **#21 Reputation & Feedback Agent** — post-dining signals; requires review/rating system active
- **#22 Staff Copilot Agent** — most complex UX integration; ship last in Phase 2

### Phase 3: Ecosystem (ship after agent tier is proven)
- **#23 MCP AI Agent Wrapper** — external API surface for third-party AI agents; requires #8 JWT and #15 Framework

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
  └─► #17 Restaurant Growth Agent (digest email uses branded layout)
  └─► #21 Reputation & Feedback Agent (recovery emails use branded layout)

#3 Branded Receipt Email
  └─► #4 Auto Pay & Leave (sends receipt on successful capture)

#5 Floorplan Dashboard
  └─► #11 Table Wait Time Estimation (shares table state model)

#8 JWT Token Management
  └─► #9 Partner Integrations (needs JWT auth for API endpoints)
  └─► #23 MCP AI Agent Wrapper (needs JWT for agent API access)

#13 Cost Insights + Pricing Publisher
  └─► #12 Dynamic Pricing Plans (needs cost data to compute prices)

#14 Heroku Cost Inventory
  └─► #13 Cost Insights (feeds infra cost data)

MenuVersion System (BUILT — no action required)
  └─► #10 Menu Experiments (dependency satisfied)

#15 Agent Framework
  └─► #16 Menu Import Agent
  └─► #17 Restaurant Growth Agent
  └─► #18 Customer Concierge Agent
  └─► #19 Menu Optimization Agent
  └─► #20 Service Operations Agent
  └─► #21 Reputation & Feedback Agent
  └─► #22 Staff Copilot Agent
  └─► #23 MCP AI Agent Wrapper (also needs #8)

#16 Menu Import Agent
  └─► (extends existing OcrMenuImport pipeline — no new downstream deps)

#17 Restaurant Growth Agent
  └─► #19 Menu Optimization Agent (shares performance-read patterns and toolbox)

#20 Service Operations Agent
  └─► (requires Kitchen/Station dashboards and ActionCable channels — all exist)

#26 Two-Factor Authentication
  └─► (no downstream dependents in v1; Devise + Redis already present)

#27 Employee Role Promotion
  └─► (depends on Employee model — already built; EmployeeRoleAudit is new)
  └─► #2 Branded Email (uses branded mailer for role-change notification)

#28 Bulk Employee Invitation
  └─► (depends on StaffInvitation model — already built)
  └─► #2 Branded Email (invitation emails use branded layout)

#29 Weight-Based Pricing
  └─► (no upstream blockers; Menuitem + Ordritem already exist)

#30 Nearby Menus Map
  └─► (no upstream blockers; PostGIS availability must be confirmed)

#31 Strikepay Integration
  └─► #3 Branded Receipt Email (post-payment tipping prompt appears on receipt/post-payment screen)
  └─► (Strikepay platform API agreement is a hard pre-development gate)
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

## AI Agent Open Questions (require resolution before #15 enters development)

The following questions must be resolved before the Agent Framework sprint begins. They affect DB schema, LLM provider selection, and GDPR posture:

1. **LLM provider strategy**: OpenAI only in v1, or build a provider-agnostic adapter from the start? Recommendation: OpenAI-only with an abstraction layer. Decision needed.
2. **AgentPolicy self-service**: Can restaurant owners modify their auto-approve/escalate policies from a self-service UI, or is this admin-managed in v1? Affects the back-office UI scope.
3. **Audit log retention**: What is the retention period for `ToolInvocationLog` and `AgentWorkflowRun` records? Recommendation: 90 days. Legal/compliance input needed.
4. **PgBouncer transaction pooling**: Is PgBouncer active in production? If yes, LISTEN/NOTIFY is unavailable for domain event dispatch. The polling approach (Sidekiq cron polls `agent_domain_events`) is the safe default.
5. **GDPR / AI processing**: Passing restaurant order data and customer dietary preferences to OpenAI's API — is this covered by the current DPA with OpenAI, and does it require customer disclosure in the privacy policy? Requires legal review before any customer-facing agent (especially #18 Customer Concierge) goes live.
6. **Review platform ingestion** (for #21 Reputation Agent): Does the platform currently receive Google/TripAdvisor reviews via API? If not, the Reputation Agent's `review.received` trigger is limited to in-app checkout ratings only in v1. Needs product confirmation.

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

The following requirements are implied by existing specs but do not yet have standalone feature files:

| Implied Feature | Implied By | Urgency | Status |
|----------------|-----------|---------| -------|
| MenuVersion System | Menu Experiments (#10) | High — hard dependency | RESOLVED — fully built; see `menu-versioning-system.md` |
| Bill Splitting (referenced in Auto Pay) | Auto Pay & Leave (#4) | Post-launch | Open |
| Twilio / SMS provider integration | Receipt Email (#3), Wait Time (#11) | Post-launch stretch | Open |
| Ordr state machine documentation | Auto Pay (#4), Floorplan (#5) | Pre-development clarification | Open |
| Restaurant onboarding checklist / progress tracking | Branded Email (#2) | Post-launch | Open |
| In-app star rating at checkout | Reputation & Feedback Agent (#21) | Required before #21 enters development | Open — confirm whether this exists |
| Review platform ingestion (Google/TripAdvisor API) | Reputation & Feedback Agent (#21) | Post-launch | Open |
| Discount/promo code system | Reputation & Feedback Agent (#21) | Required for "offer discount" action | Open — confirm whether this exists |
| `agent_domain_events` table | Agent Framework (#15) | Hard dependency for all agents | Specified in Agent Framework spec — new |
| Domain event emitters on existing models | Agent Framework (#15) | Hard dependency | Specified per agent — extend existing callbacks |
| `EmployeeRoleAudit` model | Employee Role Promotion (#27) | Hard dependency | New — specified in #27 spec |
| PostGIS availability in production | Nearby Menus Map (#30) | Must confirm before building spatial query service | Open — confirm with infra |
| Strikepay platform API model (marketplace vs standalone) | Strikepay Integration (#31) | Hard pre-development gate | Open — confirm with Strikepay BD before any dev |
| `calculated_price` vs `unit_price` column on Ordritem | Weight-Based Pricing (#29) | Affects migration design | Open — confirm exact column name in schema |
| Blog CMS implementation decision | mellow-menu-blog.md (marketing) | Engineering decision needed before build | Open — Rails ActionText vs headless CMS |
| AI feature landing pages (Sommelier, Whiskey Ambassador) | Marketing briefs | S-effort Rails views when marketing is ready | Open — awaiting marketing sign-off |

---

## Key Architectural Decisions Made During Prioritisation

1. **QR Security before Auto Pay**: A `DiningSession` is a prerequisite for safe payment method capture. Security cannot be retrofitted after payment flows are live.
2. **Branded emails before receipts**: The receipt mailer inherits the branded layout. Building them in sequence avoids rework.
3. **Admin JWT before Partner Integrations**: Partner API endpoints require the JWT authentication layer that #8 provides.
4. **Heroku Inventory before Cost Publisher before Dynamic Pricing**: These three form a strict dependency chain. They cannot be built in parallel.
5. **MenuVersion system is fully built**: Confirmed via codebase inspection. Menu Experiments (#10) only needs QR Security (#1) to ship first.
6. **R&D items explicitly excluded from sprint capacity** until launch blockers (#1, #2, #3) and at least two launch enhancers (#4, #5) are shipped.
7. **Payments always via Orchestrator**: No direct Stripe/Square calls in any new feature.
8. **Admin cost tooling in `Admin::` namespace, never Madmin**: Confirmed across #12 and #13 specs.
9. **Agent Framework is a prerequisite for all agent work**: No individual agent ships before the framework's models, runner, toolbox, and approval UI are in place. Building agents on ad-hoc pipelines creates unmanageable technical debt.
10. **Agent Framework placed at #15, not earlier**: The launch blockers (#1–#3) and high-value enhancers (#4–#7) must not be delayed to fund agent infrastructure. The agent tier is a post-launch competitive differentiator, not a launch requirement.
11. **Service Operations Agent uses rule-based fast path for simple signals**: LLM calls for deterministic congestion thresholds (queue depth, stock levels) are wasteful. Reserve LLM calls for ambiguous multi-signal reasoning. This reduces cost and latency.
12. **No agent ever writes to live data without either auto-approval (per policy) or an explicit human confirmation**: This is a non-negotiable architectural principle across all agents. Enforced at the `Agents::PolicyEvaluator` and `Agents::ArtifactWriter` level, not just the UI.
13. **MCP Wrapper depends on both JWT (#8) and Agent Framework (#15)**: The external MCP surface exposes the same toolbox that internal agents use. Building it before the internal toolbox is proven would create a public API backed by unstable infrastructure. Renumbered from #15 to #23.
14. **Customer-facing agents (Concierge #18) require GDPR review before launch**: Passing dietary preference data to OpenAI's API in a customer-facing context requires legal sign-off. This is a blocker for #18 specifically — log it as a pre-development gate.
15. **Employee roles live on `Employee`, not `User`**: The Employee Role Promotion spec (#27) was corrected during refinement — roles (`staff/manager/admin`) are scoped per restaurant on the `Employee` model. Adding role columns to `User` would break the multi-restaurant model where one user can be staff at restaurant A and admin at restaurant B.
16. **Strikepay requires `Payments::Orchestrator` adapter, not direct API calls**: All third-party payment API calls go through the Orchestrator. A `Payments::StrikepayAdapter` must be created before any Strikepay API calls are made. The Strikepay platform API model (marketplace vs standalone accounts) must be confirmed before architecture is finalised.
17. **Nearby Menus Map uses Stimulus, not React**: The raw spec proposed React components. All frontend work uses Hotwire (Turbo + Stimulus). The map provider JS SDK is wrapped in a Stimulus controller loaded lazily.
18. **Marketing/analysis documents are not dev specs**: Nine documents in `backlog/marketing/`, `backlog/competitor-analysis/`, and `marketing/` are strategy briefs and vendor evaluations. They have been dispositioned with classification headers but do not generate engineering tickets directly. The blog CMS and AI feature landing pages (S effort each) will enter the backlog as small engineering tickets when marketing is ready to execute.
