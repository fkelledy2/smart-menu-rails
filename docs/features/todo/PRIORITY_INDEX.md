# mellow.menu Feature Backlog — Priority Index

**Last updated**: 2026-03-27 (CRM Sales Funnel #9 COMPLETED 2026-03-27)
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
| ~~#4~~ | ~~Auto Pay & Leave~~ | ~~Launch Enhancer~~ | L | — | COMPLETED 2026-03-25 — spec at `docs/features/completed/auto-pay-and-leave-combined.md` |
| ~~#5~~ | ~~Floorplan Dashboard~~ | ~~Launch Enhancer~~ | M | — | COMPLETED 2026-03-25 — spec at `docs/features/completed/floorplan.md` |
| ~~#6~~ | ~~Pre-Configured Marketing QRs~~ | ~~Launch Enhancer~~ | M | #1 (token infra) | COMPLETED 2026-03-25 — spec at `docs/features/completed/pre-config-qrs.md` |
| ~~#7~~ | ~~Homepage Demo Booking & Video~~ | ~~Launch Enhancer~~ | S | None | COMPLETED 2026-03-26 — spec at `docs/features/completed/homepage-demo-booking-feature-request.md` |
| ~~#8~~ | ~~JWT Token Management (API)~~ | ~~Post-Launch~~ | L | Existing admin auth | COMPLETED 2026-03-27 — spec at `docs/features/completed/mellow-admin-jwt-token-management-feature-request.md` |
| ~~#9~~ | ~~CRM Sales Funnel~~ | ~~Growth~~ | L | Admin auth, ActionMailer, Calendly webhook | **COMPLETED 2026-03-27** — spec at `docs/features/completed/crm-sales-funnel.md` |
| #10 | Partner Integrations (Event-Driven) | Post-Launch | M | #8, Stripe webhooks | Ecosystem play; required by workforce/CRM partners |
| #11 | Menu Experiments (A/B Testing) | Post-Launch | M | #1 (DiningSession built); MenuVersion BUILT | Elevated: MenuVersion dependency resolved — all blockers done |
| #12 | Table Wait Time Estimation | Post-Launch | L | #5 (completed), Tablesetting | Operations win; differentiates for high-footfall walk-in restaurants |
| #13 | Dynamic Pricing Plans (Cost-Indexed) | Post-Launch | L | #14, #15 | Sustainable margin management at scale |
| #14 | Cost Insights + Pricing Model Publisher | Post-Launch | L | #15 | Admin system enabling #13; required before pricing models can be published |
| #15 | Heroku Cost Inventory | Post-Launch | S | Admin auth, HEROKU_PLATFORM_API_TOKEN | Feeds #14 with accurate infra cost data |
| #16 | Agent Framework — Shared Infrastructure | Post-Launch | L | OpenAI API, Sidekiq, PostgreSQL | Foundation for all AI agent work; must ship before any individual agent |
| #17 | Menu Import Agent | Post-Launch | M | #16 Agent Framework | Highest-value onboarding accelerator; reduces time-to-first-menu from hours to minutes |
| #18 | Restaurant Growth Agent | Post-Launch | M | #16 Agent Framework, analytics services | Weekly digest turns raw data into actionable owner insights; low risk, clear ROI |
| #19 | Customer Concierge Agent | Post-Launch | M | #16 Agent Framework, SmartMenu view | Customer-facing differentiation; drives order value uplift via natural-language discovery |
| #20 | Menu Optimization Agent | Post-Launch | M | #16, #18 patterns, 14+ days order data | Structured change-set proposals; builds on Growth Digest patterns; drives conversion |
| #21 | Service Operations Agent | Post-Launch | M | #16, Kitchen/Station dashboards, ActionCable | Real-time ops intelligence; reduces kitchen congestion and service recovery lag |
| #22 | Reputation & Feedback Agent | Post-Launch | M | #16, in-app rating system, email mailers | Protects revenue by surfacing and recovering negative signals before they compound |
| #23 | Staff Copilot Agent | Post-Launch | L | #16, back-office service layer | NL interface to back office; biggest UX integration effort; ship after agent patterns proven |
| #24 | MCP AI Agent Wrapper | Post-Launch | XL | #8 JWT, #16 Agent Framework, legal review | External AI agent ecosystem play; not revenue-critical until agent tier is proven internally |
| #25 | CDN Evaluation / Implementation | Post-Launch | S | Measured TTFB > 500ms | Deferred — revisit at traffic scale triggers |
| #26+ | R&D Initiatives (Floor OS) | R&D | Various | Core product stable | Strategic vision; not sprint work until launch blockers ship |
| #27 | Two-Factor Authentication | Post-Launch | M | Devise (built), Redis (built) | Security hardening for accounts controlling payments; increasingly expected by enterprise customers |
| #28 | Employee Role Promotion | Post-Launch | S | Employee model (built) | Enables restaurant teams to grow organically without manual admin intervention; audit trail included |
| #29 | Bulk Employee Invitation | Post-Launch | M | StaffInvitation (built), Sidekiq (built) | Reduces onboarding friction for multi-staff restaurants; leverages existing invitation infrastructure |
| #30 | Weight-Based Menu Item Pricing | Post-Launch | M | Menuitem model, Ordritem model, KDS | Unlocks premium dining and butcher/seafood segments that require per-weight pricing |
| #31 | Nearby Menus Map | Post-Launch | L | Geocoding data, map provider API key | Consumer-facing discovery surface; organic acquisition channel for new restaurant sign-ups |
| #32 | Strikepay Integration (Staff Tipping) | Post-Launch | L | Payments::Orchestrator, Strikepay API agreement | Staff satisfaction and retention differentiator; compliance-heavy — Strikepay platform API confirmation required before build |

> **Note on March 2026 additions (fourth pass — 2026-03-27)**: Two previously unclassified items have been reviewed and dispositioned: (1) **Square Integration** (`backlog/square-integration.md`) is confirmed In Progress (Epics 1–6 complete, pending alpha testing). It is not ranked in the priority table because it is already under active development. It uses `Payments::Orchestrator` / `Payments::SquareAdapter` correctly. Completion unblocks Square-market restaurant acquisition. Track progress separately — alpha testing and Epic 8 finalisation are the immediate next steps. (2) **Menu Item Profit Margin Tracking** (`backlog/menu-item-profit-margin-tracking.md`) — Phases 1–3 are complete as of 2026-03-17. Phase 4 (advanced analytics + AI recommendations integration) is ready for implementation. This feeds Cost Insights (#14) and the Menu Optimization Agent (#20). It does not block any ranked item but Phase 4 should be scoped as part of #14 sprint planning.

> **Note on March 2026 additions (third pass)**: CRM Sales Funnel inserted at #9 (2026-03-27). Rationale: the sales team needs a structured acquisition pipeline before launch to convert inbound interest into paying customers; this is a growth-critical internal tool, not a restaurant-facing feature. All downstream items shifted by one (#10–#32). Agent Framework internal references updated from #15 to #16. Spec at `docs/features/todo/backlog/crm-sales-funnel.md`.

> **Note on March 2026 additions (first pass)**: AI agent tier (#16–#23) added 2026-03-24. The MCP AI Agent Wrapper depends on both JWT (#8) and Agent Framework (#16). CDN Evaluation deferred until traffic triggers at #25.

> **Note on March 2026 additions (second pass)**: Ranks #27–#32 are six new product specs (2FA, Employee Role Promotion, Bulk Employee Invite, Weight-Based Pricing, Nearby Menus Map, Strikepay Integration) refined from raw requirements added 2026-03-23. All are classified Post-Launch. Key architectural corrections applied during refinement: (1) Employee Role Promotion re-scoped to target `Employee` model role enum, not `User`; (2) Bulk Employee Invite extended `StaffInvitation` model rather than replacing it; (3) Nearby Menus Map replaced React components with Stimulus/Hotwire pattern; (4) Strikepay Integration routes all API calls through `Payments::Orchestrator` / `Payments::StrikepayAdapter`, with a hard pre-development gate pending Strikepay platform API confirmation. Nine marketing/analysis documents were also classified and dispositioned (not dev specs; no new engineering tickets derived).

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

All launch blockers (#1–#7) are completed. The platform is live-capable. The following represent the highest-value next actions, ordered by immediate impact on revenue and growth:

### Track A: Sales Velocity (Highest immediate business impact)
**Feature #9 — CRM Sales Funnel**

The sales team needs this now to convert inbound interest into paying customers. Without a structured pipeline, leads are being tracked manually. This is the single feature most likely to directly increase MRR in the next 30 days.

Deliverables in priority order:
1. Migrations: `CrmLead`, `CrmLeadNote`, `CrmLeadAudit`, `CrmEmailSend`
2. Pundit policies: `CrmLeadPolicy`, `CrmLeadNotePolicy`, `CrmEmailSendPolicy`
3. `Crm::LeadTransitionService` — stage state machine
4. Kanban board UI (`/admin/crm/leads`) with Stimulus + Sortable.js
5. Lead detail panel with notes, activity log, email compose
6. Calendly webhook handler + `Crm::CalendlyWebhookVerifier`
7. `CrmMailer#lead_follow_up` using branded layout

Estimated: 3–4 developer weeks

### Track B: API & Integrations Foundation (Unblocks #10 and enterprise sales)
**Feature #8 — JWT Token Management**

Enterprise restaurant groups and integration partners are asking for programmatic access. This also unblocks Partner Integrations (#10) and the MCP Wrapper (#24). Can run in parallel with Track A.

Deliverables:
1. `create_admin_jwt_tokens` + `create_jwt_token_usage_logs` migrations
2. `Jwt::TokenGenerator`, `Jwt::TokenValidator`, `Jwt::ScopeEnforcer` services
3. `Admin::JwtTokensController` with revoke, send_email, download_link
4. `JwtAuthenticated` concern for API endpoint protection
5. `JwtTokenExpiryNotificationJob`
6. Enable Flipper flag: `jwt_api_access`

Estimated: 3–4 developer weeks

### Track C: Quick Wins — Team Management (S-effort, high operational value)
**Feature #28 — Employee Role Promotion** (S effort — can ship in days)

Low complexity, high operational value for restaurants onboarding multi-role teams. Ship this between larger tracks to show momentum.

Deliverables:
1. `create_employee_role_audits` migration
2. Extend `EmployeePolicy#change_role?` and `#view_role_history?`
3. `Employees::RoleChangeService`
4. `EmployeeMailer#role_changed` (uses built branded layout)
5. "Change Role" UI with Turbo Modal

Estimated: 3–5 developer days

---

## AI Agent Tier — Build Sequence

The AI agent features (#16–#23) form a coherent product tier that should be built as a sequential programme after the launch blockers (#1–#7, all completed) and at least the CRM (#9) and JWT (#8) work has shipped. The internal build sequence is strict:

### Phase 0: Agent Framework (#16) — prerequisite for all agents
Build the shared infrastructure: workflow models, runner, toolbox, policy evaluator, artifact writer, approval router, Sidekiq queues, and the AI Workbench UI. Estimated: 4–6 developer weeks.

### Phase 1: First Agents (can overlap; all build on the same toolbox)
- **#17 Menu Import Agent** — highest onboarding value; extends existing OCR pipeline
- **#18 Restaurant Growth Agent** — lowest risk first agent; read-only plus advisory
- **#19 Customer Concierge Agent** — customer-facing differentiation; requires streaming LLM responses

Ship Phase 1 agents once the framework is stable (at least one full run through the approval workflow in production). Estimated: 2–3 developer weeks per agent.

### Phase 2: Operational Agents (ship in any order after Phase 1 is live)
- **#20 Menu Optimization Agent** — extends Growth Digest with executable change sets
- **#21 Service Operations Agent** — live order-flow intelligence; highest latency sensitivity
- **#22 Reputation & Feedback Agent** — post-dining signals; requires review/rating system active
- **#23 Staff Copilot Agent** — most complex UX integration; ship last in Phase 2

### Phase 3: Ecosystem (ship after agent tier is proven)
- **#24 MCP AI Agent Wrapper** — external API surface for third-party AI agents; requires #8 JWT and #16 Framework

---

## Dependencies Graph

```
All launch blockers (#1–#7) are COMPLETED. Dependencies below reflect the active backlog.

#8 JWT Token Management
  └─► #10 Partner Integrations (needs JWT auth for API endpoints)
  └─► #24 MCP AI Agent Wrapper (needs JWT for agent API access)

#9 CRM Sales Funnel
  └─► (no downstream dependents — internal sales tool)

#11 Menu Experiments
  └─► (all dependencies satisfied: DiningSession built by #1, MenuVersion built)

#12 Table Wait Time Estimation
  └─► (Floorplan Dashboard completed; Tablesetting model exists)

#15 Heroku Cost Inventory
  └─► #14 Cost Insights + Pricing Publisher (feeds infra cost data)

#14 Cost Insights + Pricing Publisher
  └─► #13 Dynamic Pricing Plans (needs cost data to compute prices)

MenuVersion System (BUILT — no action required)
  └─► #11 Menu Experiments (dependency satisfied)

Menu Item Profit Margin Tracking (Phases 1–3 BUILT — Phase 4 ready)
  └─► #14 Cost Insights (Phase 4 analytics feed into cost insights)
  └─► #20 Menu Optimization Agent (margin data used in optimization proposals)

Square Integration (IN PROGRESS — Epics 1–6 complete, alpha testing pending)
  └─► (feeds Payments::Orchestrator — no dependency on ranked backlog items)

#16 Agent Framework
  └─► #17 Menu Import Agent
  └─► #18 Restaurant Growth Agent
  └─► #19 Customer Concierge Agent
  └─► #20 Menu Optimization Agent
  └─► #21 Service Operations Agent
  └─► #22 Reputation & Feedback Agent
  └─► #23 Staff Copilot Agent
  └─► #24 MCP AI Agent Wrapper (also needs #8)

#17 Menu Import Agent
  └─► (extends existing OcrMenuImport pipeline — no new downstream deps)

#18 Restaurant Growth Agent
  └─► #20 Menu Optimization Agent (shares performance-read patterns and toolbox)

#21 Service Operations Agent
  └─► (requires Kitchen/Station dashboards and ActionCable channels — all exist)

#27 Two-Factor Authentication
  └─► (no downstream dependents in v1; Devise + Redis already present)

#28 Employee Role Promotion
  └─► (depends on Employee model — already built; EmployeeRoleAudit is new)
  └─► Branded Email built — uses branded mailer for role-change notification

#29 Bulk Employee Invitation
  └─► (depends on StaffInvitation model — already built)
  └─► Branded Email built — invitation emails use branded layout

#30 Weight-Based Pricing
  └─► (no upstream blockers; Menuitem + Ordritem already exist)

#31 Nearby Menus Map
  └─► (no upstream blockers; PostGIS availability must be confirmed with infra)

#32 Strikepay Integration
  └─► Branded Receipt Email (built) — tipping prompt appears on post-payment screen
  └─► (Strikepay platform API agreement is a hard pre-development gate — do not start without this)
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

## AI Agent Open Questions (require resolution before #16 enters development)

The following questions must be resolved before the Agent Framework sprint begins. They affect DB schema, LLM provider selection, and GDPR posture:

1. **LLM provider strategy**: OpenAI only in v1, or build a provider-agnostic adapter from the start? Recommendation: OpenAI-only with an abstraction layer. Decision needed.
2. **AgentPolicy self-service**: Can restaurant owners modify their auto-approve/escalate policies from a self-service UI, or is this admin-managed in v1? Affects the back-office UI scope.
3. **Audit log retention**: What is the retention period for `ToolInvocationLog` and `AgentWorkflowRun` records? Recommendation: 90 days. Legal/compliance input needed.
4. **PgBouncer transaction pooling**: Is PgBouncer active in production? If yes, LISTEN/NOTIFY is unavailable for domain event dispatch. The polling approach (Sidekiq cron polls `agent_domain_events`) is the safe default.
5. **GDPR / AI processing**: Passing restaurant order data and customer dietary preferences to OpenAI's API — is this covered by the current DPA with OpenAI, and does it require customer disclosure in the privacy policy? Requires legal review before any customer-facing agent (especially #19 Customer Concierge) goes live.
6. **Review platform ingestion** (for #22 Reputation Agent): Does the platform currently receive Google/TripAdvisor reviews via API? If not, the Reputation Agent's `review.received` trigger is limited to in-app checkout ratings only in v1. Needs product confirmation.

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
| MenuVersion System | Menu Experiments (#11) | High — hard dependency | RESOLVED — fully built; see `menu-versioning-system.md` |
| Bill Splitting (referenced in Auto Pay) | Auto Pay & Leave (#4, completed) | Post-launch | Open |
| Twilio / SMS provider integration | Receipt Email (#2, completed), Wait Time (#12) | Post-launch stretch | Open |
| Ordr state machine documentation | Auto Pay (#4, completed), Floorplan (#5, completed) | Pre-development clarification | Open |
| Restaurant onboarding checklist / progress tracking | Branded Email (#1, completed) | Post-launch | Open |
| In-app star rating at checkout | Reputation & Feedback Agent (#22) | Required before #22 enters development | Open — confirm whether this exists |
| Review platform ingestion (Google/TripAdvisor API) | Reputation & Feedback Agent (#22) | Post-launch | Open |
| Discount/promo code system | Reputation & Feedback Agent (#22) | Required for "offer discount" action | Open — confirm whether this exists |
| `agent_domain_events` table | Agent Framework (#16) | Hard dependency for all agents | Specified in Agent Framework spec — new |
| Domain event emitters on existing models | Agent Framework (#16) | Hard dependency | Specified per agent — extend existing callbacks |
| `EmployeeRoleAudit` model | Employee Role Promotion (#28) | Hard dependency | New — specified in #28 spec |
| PostGIS availability in production | Nearby Menus Map (#31) | Must confirm before building spatial query service | Open — confirm with infra |
| Strikepay platform API model (marketplace vs standalone) | Strikepay Integration (#32) | Hard pre-development gate | Open — confirm with Strikepay BD before any dev |
| `calculated_price` vs `unit_price` column on Ordritem | Weight-Based Pricing (#30) | Affects migration design | Open — confirm exact column name in schema |
| Blog CMS implementation decision | mellow-menu-blog.md (marketing) | Engineering decision needed before build | Open — Rails ActionText vs headless CMS |
| AI feature landing pages (Sommelier, Whiskey Ambassador) | Marketing briefs | S-effort Rails views when marketing is ready | Open — awaiting marketing sign-off |
| Square Integration alpha testing completion | `backlog/square-integration.md` | High — in progress; Epics 1–6 done | Active — Epic 7 finalisation + Epic 8 alpha sign-off |
| Profit Margin Tracking Phase 4 | `backlog/menu-item-profit-margin-tracking.md` | Medium — feeds #14 Cost Insights | Ready for implementation; scope as part of #14 sprint |

---

## Key Architectural Decisions Made During Prioritisation

1. **QR Security before Auto Pay**: A `DiningSession` is a prerequisite for safe payment method capture. Security cannot be retrofitted after payment flows are live. Both are now completed.
2. **Branded emails before receipts**: The receipt mailer inherits the branded layout. Building them in sequence avoids rework. Both are now completed.
3. **Admin JWT before Partner Integrations**: Partner API endpoints require the JWT authentication layer that #8 provides.
4. **Heroku Inventory (#15) before Cost Publisher (#14) before Dynamic Pricing (#13)**: These three form a strict dependency chain. They cannot be built in parallel.
5. **MenuVersion system is fully built**: Confirmed via codebase inspection. Menu Experiments (#11) is unblocked — all dependencies resolved.
6. **R&D items explicitly excluded from sprint capacity** until launch blockers (#1–#7, all completed) and core post-launch revenue features (#8–#9) have shipped.
7. **Payments always via Orchestrator**: No direct Stripe/Square calls in any new feature. Square Integration follows this correctly via `Payments::SquareAdapter`.
8. **Admin cost tooling in `Admin::` namespace, never Madmin**: Confirmed across #13 and #14 specs.
9. **Agent Framework (#16) is a prerequisite for all agent work**: No individual agent ships before the framework's models, runner, toolbox, and approval UI are in place. Building agents on ad-hoc pipelines creates unmanageable technical debt.
10. **Agent Framework placed at #16, after CRM (#9) and JWT (#8)**: The sales pipeline (CRM) and API access (JWT) deliver immediate revenue impact. The agent tier is a post-launch competitive differentiator and should not delay sales tooling.
11. **Service Operations Agent uses rule-based fast path for simple signals**: LLM calls for deterministic congestion thresholds (queue depth, stock levels) are wasteful. Reserve LLM calls for ambiguous multi-signal reasoning. This reduces cost and latency.
12. **No agent ever writes to live data without either auto-approval (per policy) or an explicit human confirmation**: This is a non-negotiable architectural principle across all agents. Enforced at the `Agents::PolicyEvaluator` and `Agents::ArtifactWriter` level, not just the UI.
13. **MCP Wrapper (#24) depends on both JWT (#8) and Agent Framework (#16)**: The external MCP surface exposes the same toolbox that internal agents use. Building it before the internal toolbox is proven would create a public API backed by unstable infrastructure.
14. **Customer-facing agents (Concierge #19) require GDPR review before launch**: Passing dietary preference data to OpenAI's API in a customer-facing context requires legal sign-off. This is a hard pre-development gate for #19 specifically.
15. **Employee roles live on `Employee`, not `User`**: The Employee Role Promotion spec (#28) was corrected during refinement — roles (`staff/manager/admin`) are scoped per restaurant on the `Employee` model. Adding role columns to `User` would break the multi-restaurant model where one user can be staff at restaurant A and admin at restaurant B.
16. **Strikepay (#32) requires `Payments::Orchestrator` adapter, not direct API calls**: All third-party payment API calls go through the Orchestrator. A `Payments::StrikepayAdapter` must be created before any Strikepay API calls are made. The Strikepay platform API model (marketplace vs standalone accounts) must be confirmed before architecture is finalised. Do not start without this.
17. **Nearby Menus Map (#31) uses Stimulus, not React**: The raw spec proposed React components. All frontend work uses Hotwire (Turbo + Stimulus). The map provider JS SDK is wrapped in a Stimulus controller loaded lazily.
18. **Marketing/analysis documents are not dev specs**: Nine documents in `backlog/marketing/`, `backlog/competitor-analysis/`, and `marketing/` are strategy briefs and vendor evaluations. They have been dispositioned with classification headers but do not generate engineering tickets directly. The blog CMS and AI feature landing pages (S effort each) will enter the backlog as small engineering tickets when marketing is ready to execute.
19. **Square Integration is in-progress and tracked separately**: Epics 1–6 are complete. The integration uses `Payments::Orchestrator` / `Payments::SquareAdapter` correctly. It does not appear in the ranked priority table because it is under active development — progress is tracked via Epic 7 finalisation and Epic 8 alpha sign-off, not via sprint priority order.
20. **Profit Margin Tracking Phases 1–3 are built**: The `MenuitemCost` model, versioning, AI cost estimation, and basic reporting exist. Phase 4 (advanced analytics and AI recommendations integration) should be scoped as part of the Cost Insights (#14) sprint — the data it provides feeds the pricing model compiler.
