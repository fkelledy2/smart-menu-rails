# mellow.menu Feature Backlog — Priority Index

**Last updated**: 2026-04-01 (nineteenth pass — Realtime Ordritem Tracking #34 COMPLETED) (seventeenth pass — daily prioritisation run; IQ-1 Naked Domain confirmed fully COMPLETED including ops steps; Sprint Recommendation updated to reflect current next best actions: Square alpha + Track D Employee Role Promotion + Track F Agent Framework; stale Track A/B/C completed-item deliverable lists retired; Refined flags added to spec files #28–#34)
**Naked Domain Canonical Strategy (IQ-1)**: COMPLETED 2026-03-31 — DomainRedirect middleware live; spec at `docs/features/completed/naked-domain-canonical-strategy.md`
**QR Code Security (#1)**: COMPLETED 2026-03-24 — Phase 1 shipped; spec at `docs/features/completed/qr-security.md`
**Branded Email Styling (#1)**: COMPLETED 2026-03-24 — spec at `docs/features/completed/branded-email-styling-feature-request.md`
**Branded Receipt Email (#2)**: COMPLETED 2026-03-25 — spec at `docs/features/completed/branded-receipt-email-feature-request.md`
**Menu Experiments (#12)**: COMPLETED 2026-03-29 — spec at `docs/features/completed/08-menu-experiments-ab-testing.md`
**Table Wait Time Estimation (#13)**: COMPLETED 2026-03-29 — spec at `docs/features/completed/table-wait-time-estimation-feature-request.md`
**Smartmenu Preview Modes (#36)**: COMPLETED 2026-03-31 — SmartmenuPreviewToken live; staff-mode-indicator removed; spec at `docs/features/todo/features/36-smartmenu-preview-modes.md`
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
| ~~#9~~ | ~~CRM Sales Funnel~~ | ~~Growth~~ | L | Admin auth, ActionMailer, Calendly webhook | COMPLETED 2026-03-27 — spec at `docs/features/completed/crm-sales-funnel.md` |
| ~~#10~~ | ~~Smartmenu Theming~~ | ~~Launch Enhancer~~ | M | None | COMPLETED 2026-03-28 — spec at `docs/features/completed/smartmenu-theming.md` |
| ~~#11~~ | ~~Partner Integrations (Event-Driven)~~ | ~~Post-Launch~~ | M | #8, Stripe webhooks | COMPLETED 2026-03-29 — spec at `docs/features/completed/06-partner-integrations-event-driven.md` |
| ~~#12~~ | ~~Menu Experiments (A/B Testing)~~ | ~~Post-Launch~~ | M | #1 (DiningSession built); MenuVersion BUILT | COMPLETED 2026-03-29 — spec at `docs/features/completed/08-menu-experiments-ab-testing.md` |
| ~~#13~~ | ~~Table Wait Time Estimation~~ | ~~Post-Launch~~ | L | #5 (completed), Tablesetting | COMPLETED 2026-03-29 — spec at `docs/features/completed/table-wait-time-estimation-feature-request.md` |
| ~~IQ-1~~ | ~~Naked Domain Canonical Strategy~~ | ~~Infrastructure~~ | S | DNS provider access, Heroku CLI | COMPLETED 2026-03-31 — code shipped; ops DNS/Heroku steps remain; spec at `docs/features/completed/naked-domain-canonical-strategy.md` |
| #14 | Dynamic Pricing Plans (Cost-Indexed) | Post-Launch | L | #15, #16 | Sustainable margin management at scale |
| #15 | Cost Insights + Pricing Model Publisher | Post-Launch | L | #16 | Admin system enabling #14; required before pricing models can be published |
| #16 | Heroku Cost Inventory | Post-Launch | S | Admin auth, HEROKU_PLATFORM_API_TOKEN | Feeds #15 with accurate infra cost data |
| ~~#17~~ | ~~Agent Framework — Shared Infrastructure~~ | ~~Post-Launch~~ | L | OpenAI API, Sidekiq, PostgreSQL | **COMPLETED 2026-04-02** — spec at `docs/features/completed/17-agent-framework.md`; user guide at `docs/features/completed/17-agent-framework-user-guide.md` |
| #18 | Menu Import Agent | Post-Launch | M | #17 Agent Framework | Highest-value onboarding accelerator; reduces time-to-first-menu from hours to minutes |
| #19 | Restaurant Growth Agent | Post-Launch | M | #17 Agent Framework, analytics services | Weekly digest turns raw data into actionable owner insights; low risk, clear ROI |
| #20 | Customer Concierge Agent | Post-Launch | M | #17 Agent Framework, SmartMenu view | Customer-facing differentiation; drives order value uplift via natural-language discovery |
| #21 | Menu Optimization Agent | Post-Launch | M | #17, #19 patterns, 14+ days order data | Structured change-set proposals; builds on Growth Digest patterns; drives conversion |
| #22 | Service Operations Agent | Post-Launch | M | #17, Kitchen/Station dashboards, ActionCable | Real-time ops intelligence; reduces kitchen congestion and service recovery lag |
| #23 | Reputation & Feedback Agent | Post-Launch | M | #17, in-app rating system, email mailers | Protects revenue by surfacing and recovering negative signals before they compound |
| #24 | Staff Copilot Agent | Post-Launch | L | #17, back-office service layer | NL interface to back office; biggest UX integration effort; ship after agent patterns proven |
| #25 | MCP AI Agent Wrapper | Post-Launch | XL | #8 JWT, #17 Agent Framework, legal review | External AI agent ecosystem play; not revenue-critical until agent tier is proven internally |
| #26 | CDN Evaluation / Implementation | Post-Launch | S | Measured TTFB > 500ms | Deferred — revisit at traffic scale triggers |
| #27+ | R&D Initiatives (Floor OS) | R&D | Various | Core product stable | Strategic vision; not sprint work until launch blockers ship |
| #28 | Two-Factor Authentication | Post-Launch | M | Devise (built), Redis (built) | Security hardening for accounts controlling payments; increasingly expected by enterprise customers |
| ~~#29~~ | ~~Employee Role Promotion~~ | ~~Post-Launch~~ | S | Employee model (built) | **COMPLETED** 2026-04-01 — spec at `docs/features/completed/29-employee-role-promotion.md`; user guide at `docs/features/completed/29-employee-role-promotion-user-guide.md` |
| #30 | Bulk Employee Invitation | Post-Launch | M | StaffInvitation (built), Sidekiq (built) | Reduces onboarding friction for multi-staff restaurants; leverages existing invitation infrastructure |
| #31 | Weight-Based Menu Item Pricing | Post-Launch | M | Menuitem model, Ordritem model, KDS | Unlocks premium dining and butcher/seafood segments that require per-weight pricing |
| #32 | Nearby Menus Map | Post-Launch | L | Geocoding data, map provider API key | Consumer-facing discovery surface; organic acquisition channel for new restaurant sign-ups |
| #33 | Strikepay Integration (Staff Tipping) | Post-Launch | L | Payments::Orchestrator, Strikepay API agreement | Staff satisfaction and retention differentiator; compliance-heavy — Strikepay platform API confirmation required before build |
| ~~#34~~ | ~~Realtime Ordritem Tracking & Passive Customer Feedback~~ | ~~Post-Launch~~ | L | Existing `OrdrChannel`, `KitchenChannel`, `StationChannel`, Sidekiq, `Ordritem` model | **COMPLETED** 2026-04-01 — spec at `docs/features/completed/34-realtime-ordritem-tracking.md`; user guide at `docs/features/completed/34-realtime-ordritem-tracking-user-guide.md` |
| #35 | Profit Margin Tracking — Phase 4 (Optimization Tools) | Post-Launch | M | Phases 1–3 complete (production); feeds #21 Menu Optimization Agent | Closes the loop from margin insight to action: menu engineering matrix, AI pricing recommendations, bundling opportunities |
| ~~#36~~ | ~~Smartmenu Preview Modes (Signed Token)~~ | ~~Launch Enhancer~~ | S | — | COMPLETED 2026-03-31 — SmartmenuPreviewToken live; staff-mode-indicator removed; ?view=staff fully retired; spec at `docs/features/todo/features/36-smartmenu-preview-modes.md` |
| IN-PROGRESS | Square Integration | Launch Enhancer | XL (mostly done) | Payments::Orchestrator, ProviderAccount model, Flipper flag | Under active development — Epics 1–8 backend/UI complete; 3 remaining items before alpha: split-bill progress UI, degraded-status email, "Reconnect" CTA |
| #37 | AI Sommelier Marketing Landing Page | Post-Launch (Marketing) | S | AI Sommelier feature live; 2–3 reference restaurants; copy + design approved | Public acquisition surface for the AI Sommelier feature; 1–2 days engineering once assets are ready |
| #38 | AI Whiskey Ambassador Marketing Landing Page | Post-Launch (Marketing) | S | #37 ships first (establishes MarketingController pattern); Whiskey Ambassador live; copy + design approved | Same pattern as #37; reuses controller and layout; distinct URL for SEO segment targeting |

> **Note on March 2026 additions (seventeenth pass — 2026-03-31)**: Daily prioritisation run. No new features added or re-ranked. Changes: (1) Sprint Recommendation updated — stale Tracks A, B, C retired (all completed); IQ-1 "ship first" guidance retired (completed); Track D (Employee Role Promotion) is now the current lead track; Square alpha three-item blockers remain the highest-revenue-unlocking parallel priority; Track F (Agent Framework #17) named as next major programme; Track G (pricing chain #16→#15→#14) documented; Quick Win Pool formalised. (2) Dependencies Graph cleaned — removed stale forward-references to #10, #12, #13. (3) `Refined: true` flags added to spec files #28, #29, #30, #31, #32, #33, #34 (previously refined in substance but flag omitted). No rank changes.

> **Note on March 2026 additions (sixteenth pass — 2026-03-31)**: **Naked Domain Canonical Strategy** (IQ-1) COMPLETED. DomainRedirect Rack middleware shipped; all `www.mellow.menu` references updated to `mellow.menu` canonical URLs; 9 tests added; ops DNS/Heroku steps documented in spec at `docs/features/completed/naked-domain-canonical-strategy.md`.

> **Note on March 2026 additions (fifteenth pass — 2026-03-31)**: **Smartmenu Preview Modes** (#36) confirmed COMPLETED. Codebase verification shows `app/models/smartmenu_preview_token.rb` is live and tested (`test/models/smartmenu_preview_token_test.rb`), `SmartmenusController` decodes `params[:preview]` via `SmartmenuPreviewToken.decode`, and the `staff-mode-indicator` block is fully absent from all views. The legacy `?view=staff` param was removed immediately rather than kept for a grace period (Open Question Q1 resolved in favour of clean removal). The `smartmenu_preview_tokens` Flipper flag was not needed as the old mechanism was gone before this shipped. Track E retired from sprint recommendation. No rank changes to remaining backlog items.

> **Note on March 2026 additions (fourteenth pass — 2026-03-31)**: **Realtime Ordritem Tracking & Passive Customer Feedback** (#34) spec reviewed against the detailed product document and confirmed fully current. The existing spec at `docs/features/todo/backlog/34-realtime-ordritem-tracking.md` and the mirrored copy at `wiki/features/todo/backlog/34-realtime-ordritem-tracking.md` both contain the complete architectural design including: `fulfillment_status` / `station` enum strategy with `prefix:` collision avoidance, `OrdritemEvent` immutability guards, `Ordritems::TransitionStatus` idempotency contract, `Ordritems::TransitionGroup` batch-first workflow, `Ordritems::BroadcastStatusChangeJob` post-commit broadcast pattern, `ordritem_tracking_controller.js` Stimulus controller, and the resolved open questions (station assignment from `Menuitem#default_station`, `OrdrChannel` auth shipped as `qr_security_v1`). No rank change. No new gems. Ready for Phase 1 development.

> **Note on March 2026 additions (thirteenth pass — 2026-03-30)**: Five previously unrefined files have been reviewed and dispositioned. (1) **Square Integration** (`backlog/square-integration.md`) is marked IN-PROGRESS (not ranked) — Epics 1–8 backend/UI are complete; three remaining items before alpha testing: split-bill progress UI, degraded-status manager notification email, and "Reconnect Square" CTA in admin UI. Alpha testing is the immediate next step. (2) **Profit Margin Tracking Phase 4** (`backlog/35-menu-item-profit-margin-tracking.md`) — Phases 1–3 are in production; Phase 4 (menu engineering matrix, AI pricing recommendations, bundling opportunity detection) is ranked #35, M-effort, Post-Launch. Feeds the Menu Optimization Agent (#21) via a shared `MenuEngineering::BundlingOpportunityService` interface. (3) **Smartmenu Preview Modes** (`features/36-smartmenu-preview-modes.md`) — ranked #36, S-effort, Launch Enhancer. Removes the intrusive staff-mode-indicator banner from the customer-facing smartmenu URL; replaces with signed `Rails.application.message_verifier` preview tokens launched from the edit page. No database changes, no new gems, no ActionCable changes in Phase 1. (4) **AI Sommelier Landing Page** (`marketing/37-ai-sommelier-landing-page.md`) — ranked #37, S-effort, Post-Launch/Marketing. Clarified that this is a Rails static view (not Next.js); engineering is 1–2 days once copy and design are ready. Gated on the feature being publicly live and 2–3 reference restaurants confirmed. (5) **AI Whiskey Ambassador Landing Page** (`marketing/38-ai-whiskey-ambassador-landing-page.md`) — ranked #38, S-effort, Post-Launch/Marketing. Same controller/layout pattern as #37; ranked downstream of it. Both marketing pages' original budget estimates ($8k–$25k frontend) are inapplicable — this is a Rails view, not a separate application.

> **Note on March 2026 additions (twelfth pass — 2026-03-30)**: **Realtime Ordritem Tracking & Passive Customer Feedback** added at #34 (Post-Launch, L effort). This feature tracks fulfillment state at the `Ordritem` level and surfaces it passively to the customer via `OrdrChannel` ActionCable broadcasts. Key architectural decision: a new `fulfillment_status` column (separate from the existing `status` enum) avoids colliding with the `Ordritem` lifecycle states (`opened → paid`). Two open questions must be resolved before Phase 1 begins: (1) `Menuitem#default_station` column strategy, and (2) whether the `OrdrChannel` subscription auth guard ships in Phase 1 or as a separate security ticket. Spec at `docs/features/todo/backlog/34-realtime-ordritem-tracking.md`.

> **Note on March 2026 additions (eleventh pass — 2026-03-30)**: **Naked Domain Canonical Strategy** added as Infrastructure Quick Win **IQ-1**. This is an S-effort ops + minimal-code task (one initializer, three config lines, one robots.txt update) with zero product dependencies. It is a pre-launch professionalism requirement: `mellow.menu` must resolve before the platform is presented to paying customers or press. It does not affect the existing rank sequence (#14–#33). The `IQ-` prefix distinguishes infrastructure quick-wins from ranked product features so the sprint table remains stable. Spec at `docs/features/todo/backlog/naked-domain-canonical-strategy.md`.

> **Note on March 2026 additions (sixth pass — 2026-03-28)**: **Full rank alignment pass** — all individual spec files updated to reflect the current rank numbers following the fifth-pass Smartmenu Theming insertion. Prior to this pass, 19 spec files still carried pre-insertion rank numbers (agent specs #17–#23, second-pass specs #27–#32, CDN #25, partner integrations #10, menu experiments #11, table wait time #12, dynamic pricing #13, cost insights #14, Heroku cost #15). All files now reflect the canonical PRIORITY_INDEX rank numbers. CRM (#9) and JWT (#8) marked complete in the ranking table. Sprint 1 Recommendation updated to reflect current next best actions: Smartmenu Theming (#10, Track A), Partner Integrations (#11, Track B), Menu Experiments (#12, Track C), Employee Role Promotion (#29, Track D quick win). Agent Framework cross-references corrected from #16 to #17 across all agent specs.

> **Note on March 2026 additions (fifth pass — 2026-03-28)**: **Smartmenu Theming** inserted at #10 as a Launch Enhancer. Rationale: this is the highest-visibility customer-facing surface in the product — every dining customer sees it. Visual differentiation directly drives restaurant satisfaction and retention, and it is a strong factor in restaurant owners recommending the platform. No dependencies, M effort, clean Rails/Hotwire/SCSS implementation. All downstream items shifted by one (#11–#33). Agent Framework internal references corrected to #17. Spec at `docs/features/todo/backlog/smartmenu-theming.md`.

> **Note on March 2026 additions (fourth pass — 2026-03-27)**: Two previously unclassified items have been reviewed and dispositioned: (1) **Square Integration** (`backlog/square-integration.md`) is confirmed In Progress (Epics 1–6 complete, pending alpha testing). It is not ranked in the priority table because it is already under active development. It uses `Payments::Orchestrator` / `Payments::SquareAdapter` correctly. Completion unblocks Square-market restaurant acquisition. Track progress separately — alpha testing and Epic 8 finalisation are the immediate next steps. (2) **Menu Item Profit Margin Tracking** (`backlog/35-menu-item-profit-margin-tracking.md`) — Phases 1–3 are complete as of 2026-03-17. Phase 4 (advanced analytics + AI recommendations integration) is ready for implementation. This feeds Cost Insights (#15) and the Menu Optimization Agent (#21). It does not block any ranked item but Phase 4 should be scoped as part of #15 sprint planning.

> **Note on March 2026 additions (third pass)**: CRM Sales Funnel inserted at #9 (2026-03-27). Rationale: the sales team needs a structured acquisition pipeline before launch to convert inbound interest into paying customers; this is a growth-critical internal tool, not a restaurant-facing feature. All downstream items shifted by one (then #10–#32, now #11–#33 after the fifth-pass Theming insertion). Spec at `docs/features/todo/backlog/crm-sales-funnel.md`.

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
| ~~**IQ-1**~~ | ~~**Naked Domain Canonical Strategy**~~ | COMPLETED 2026-03-31 — DomainRedirect middleware live; `mellow.menu` apex resolves correctly |

Note: All launch blockers and infrastructure pre-conditions are now COMPLETED. The platform is ready to accept live orders from paying restaurant customers.

**Launch status: READY.** Features #4–#13, IQ-1, and #36 are all shipped. The platform is publicly presentable. Naked domain resolves. Sales pipeline is live. The minimum viable launch set is 100% complete.

---

## Current Sprint Recommendation — Next Best Actions

**Platform state as of 2026-03-31:** All launch blockers (#1–#7), JWT (#8), CRM (#9), Smartmenu Theming (#10), Partner Integrations (#11), Menu Experiments (#12), Table Wait Time Estimation (#13), Naked Domain (IQ-1), and Smartmenu Preview Modes (#36) are COMPLETED. The platform is live-capable and publicly presentable. The sales pipeline is operational. The focus shifts to: closing the Square alpha, shipping quick-win team management tooling, and beginning the post-launch feature programme.

---

### Completed Tracks (retired from sprint planning)

~~**Track A — Smartmenu Theming (#10)**~~ COMPLETED 2026-03-28
~~**Track B — Partner Integrations (#11)**~~ COMPLETED 2026-03-29
~~**Track C — Menu Experiments (#12)**~~ COMPLETED 2026-03-29
~~**Track E — Smartmenu Preview Modes (#36)**~~ COMPLETED 2026-03-31
~~**IQ-1 — Naked Domain Canonical Strategy**~~ COMPLETED 2026-03-31

---

### Track D: Team Management Quick Win — COMPLETED 2026-04-01
~~**Feature #29 — Employee Role Promotion**~~ COMPLETED 2026-04-01

All deliverables shipped: migration, `EmployeeRoleAudit` model, `Employees::RoleChangeService`, `EmployeeRoleChangedJob`, `EmployeeMailer#role_changed`, extended `EmployeePolicy`, `EmployeeRoleAuditPolicy`, controller actions (`new_role_change`, `change_role`, `role_history`), inline Turbo Stream UI, two Stimulus controllers, `employee_role_promotion` Flipper flag, and 127 passing tests.

Next track: **#30 Bulk Employee Invitation** or **Square Integration alpha blockers** (parallel priority).

---

### Square Integration Alpha — Parallel Priority
**Feature: Square Integration** (IN-PROGRESS — Epics 1–8 backend/UI complete)

Three remaining items before the alpha cohort can begin. These are small but blocking:
1. Split-bill progress UI — display "€X of €Y paid" in the payment flow
2. Manager notification email on degraded/disconnected Square status
3. "Reconnect Square" CTA in admin UI when status is degraded

Complete these three items, then stand up the Square sandbox alpha with the first pilot restaurant cohort. This is the single highest-revenue-unlocking activity on the board — Square-market restaurants (Ireland, UK, US) cannot be acquired until alpha validates the payment flow.

Estimated: 3–5 developer days to clear the three blockers; alpha setup thereafter

---

### Track F: Agent Framework (#17) — Next Major Programme
**Feature #17 — Agent Framework — Shared Infrastructure** (L effort — 4–6 developer weeks)

All immediate quick wins and launch enhancers are completed. The Agent Framework is the highest-value next substantial build: it is the prerequisite for 8 downstream AI features (#18–#25). Nothing in the agent tier can start without it. Begin scoping once Track D and the Square alpha blockers are cleared.

Deliverables (summary — full spec at `docs/features/todo/AI/17-agent-framework.md`):
1. `AgentWorkflow`, `AgentRun`, `AgentArtifact`, `AgentApproval` models + migrations
2. `Agents::Runner` — orchestrates tool calls, handles retries, emits events
3. `Agents::Toolbox` base + first tool implementations (read-only menu + order data)
4. `Agents::PolicyEvaluator` — Pundit-integrated safety layer
5. `Agents::ArtifactWriter` — persists structured output for approval workflows
6. `Agents::ApprovalRouter` — routes high-risk actions to human review
7. `AgentRunWorker` Sidekiq queue (dedicated `agents` queue, concurrency 5)
8. AI Workbench UI — admin view of runs, artifacts, approvals
9. `agent_framework` Flipper flag

Estimated: 4–6 developer weeks

---

### Track G: Pricing Infrastructure (#16 → #15 → #14) — Post-Launch Sequence
When bandwidth allows after Tracks D/F, the pricing infrastructure chain is the next highest-ROI internal programme. Start with the smallest item (#16 Heroku Cost Inventory, S effort) to unlock the chain.

1. **#16 Heroku Cost Inventory** (S effort) — connects Heroku Platform API; feeds cost data to #15
2. **#15 Cost Insights + Pricing Publisher** (L effort) — admin system for publishing pricing models; enables #14
3. **#14 Dynamic Pricing Plans** (L effort) — cost-indexed, price-locked-at-signup plans; sustainable margin management

---

### Quick Win Pool — Pick Up Between Tracks
Items below can be slotted into any gap between larger tracks. All have full specs, no external blockers, and clear acceptance criteria.

| Feature | Effort | Why now |
|---------|--------|---------|
| #30 Bulk Employee Invitation | M | Natural follow-on to #29; reuses `StaffInvitation` + branded mailer |
| #28 Two-Factor Authentication | M | Security hygiene for payment-controlling accounts; increasingly table-stakes |
| #35 Profit Margin Phase 4 | M | Phases 1–3 in production; Phase 4 closes the insight-to-action loop; feeds #21 |

---

## AI Agent Tier — Build Sequence

The AI agent features (#17–#24) form a coherent product tier that should be built as a sequential programme after the launch blockers (#1–#7, all completed) and both the CRM (#9) and JWT (#8) work has shipped (both completed 2026-03-27). The internal build sequence is strict:

### Phase 0: Agent Framework (#17) — prerequisite for all agents
Build the shared infrastructure: workflow models, runner, toolbox, policy evaluator, artifact writer, approval router, Sidekiq queues, and the AI Workbench UI. Estimated: 4–6 developer weeks.

### Phase 1: First Agents (can overlap; all build on the same toolbox)
- **#18 Menu Import Agent** — highest onboarding value; extends existing OCR pipeline
- **#19 Restaurant Growth Agent** — lowest risk first agent; read-only plus advisory
- **#20 Customer Concierge Agent** — customer-facing differentiation; requires streaming LLM responses

Ship Phase 1 agents once the framework is stable (at least one full run through the approval workflow in production). Estimated: 2–3 developer weeks per agent.

### Phase 2: Operational Agents (ship in any order after Phase 1 is live)
- **#21 Menu Optimization Agent** — extends Growth Digest with executable change sets
- **#22 Service Operations Agent** — live order-flow intelligence; highest latency sensitivity
- **#23 Reputation & Feedback Agent** — post-dining signals; requires review/rating system active
- **#24 Staff Copilot Agent** — most complex UX integration; ship last in Phase 2

### Phase 3: Ecosystem (ship after agent tier is proven)
- **#25 MCP AI Agent Wrapper** — external API surface for third-party AI agents; requires #8 JWT (done) and #17 Agent Framework

---

## Dependencies Graph

```
Launch blockers #1–#7, JWT #8, CRM #9, Theming #10, Partner Integrations #11, Menu Experiments #12,
Table Wait Time #13, Naked Domain IQ-1, and Smartmenu Preview Modes #36 are all COMPLETED.
Dependencies below reflect only the active backlog.

#8 JWT Token Management (COMPLETED 2026-03-27)
  └─► #11 Partner Integrations (COMPLETED 2026-03-29)
  └─► #25 MCP AI Agent Wrapper (also needs #17 Agent Framework)

#16 Heroku Cost Inventory
  └─► #15 Cost Insights + Pricing Publisher (feeds infra cost data)

#15 Cost Insights + Pricing Publisher
  └─► #14 Dynamic Pricing Plans (needs cost data to compute prices)

MenuVersion System (BUILT — no action required)
  └─► #12 Menu Experiments (dependency satisfied)

Menu Item Profit Margin Tracking (Phases 1–3 BUILT — Phase 4 ready)
  └─► #15 Cost Insights (Phase 4 analytics feed into cost insights)
  └─► #21 Menu Optimization Agent (margin data used in optimization proposals)

Square Integration (IN PROGRESS — Epics 1–6 complete, alpha testing pending)
  └─► (feeds Payments::Orchestrator — no dependency on ranked backlog items)

#17 Agent Framework
  └─► #18 Menu Import Agent
  └─► #19 Restaurant Growth Agent
  └─► #20 Customer Concierge Agent
  └─► #21 Menu Optimization Agent
  └─► #22 Service Operations Agent
  └─► #23 Reputation & Feedback Agent
  └─► #24 Staff Copilot Agent
  └─► #25 MCP AI Agent Wrapper (also needs #8 — completed)

#18 Menu Import Agent
  └─► (extends existing OcrMenuImport pipeline — no new downstream deps)

#19 Restaurant Growth Agent
  └─► #21 Menu Optimization Agent (shares performance-read patterns and toolbox)

#22 Service Operations Agent
  └─► (requires Kitchen/Station dashboards and ActionCable channels — all exist)

#28 Two-Factor Authentication
  └─► (no downstream dependents in v1; Devise + Redis already present)

#29 Employee Role Promotion
  └─► (depends on Employee model — already built; EmployeeRoleAudit is new)
  └─► Branded Email built — uses branded mailer for role-change notification

#30 Bulk Employee Invitation
  └─► (depends on StaffInvitation model — already built)
  └─► Branded Email built — invitation emails use branded layout

#31 Weight-Based Pricing
  └─► (no upstream blockers; Menuitem + Ordritem already exist)

#32 Nearby Menus Map
  └─► (no upstream blockers; PostGIS availability must be confirmed with infra)

#33 Strikepay Integration
  └─► Branded Receipt Email (built) — tipping prompt appears on post-payment screen
  └─► (Strikepay platform API agreement is a hard pre-development gate — do not start without this)

#34 Realtime Ordritem Tracking
  └─► OrdrChannel (built — extends existing stream `ordr_#{id}_channel`)
  └─► KitchenChannel / StationChannel (built — adds `advance_station` handler)
  └─► Ordritem model (built — adds `fulfillment_status` + `station` columns via migration)
  └─► DiningSession token auth guard on OrdrChannel (open question — latent risk; resolve before Phase 3)
  └─► Menuitem#default_station (new column — confirm strategy before Phase 1 migration)

#35 Profit Margin Phase 4
  └─► Phases 1–3 of ProfitMarginTracking (COMPLETE — all models, services, jobs exist)
  └─► #21 Menu Optimization Agent (Phase 4 output feeds agent via shared service interface)

#36 Smartmenu Preview Modes — COMPLETED 2026-03-31
  └─► SmartmenuPreviewToken (now live — app/models/smartmenu_preview_token.rb)
  └─► SmartmenusController (updated — params[:preview] decode replaces params[:view])
  └─► No downstream dependents

Square Integration (IN-PROGRESS)
  └─► Payments::Orchestrator (built)
  └─► ProviderAccount model (extended — Epics 1–2 complete)
  └─► Flipper `square_payments` flag (registered)
  └─► (feeds no ranked backlog items as a dependency)

#37 AI Sommelier Landing Page
  └─► AI Sommelier feature publicly accessible (gating condition — not a code dependency)
  └─► Marketing copy + design approved (gating condition — not a code dependency)

#38 AI Whiskey Ambassador Landing Page
  └─► #37 (establishes MarketingController and layout pattern)
  └─► AI Whiskey Ambassador feature publicly accessible (gating condition)
  └─► Marketing copy + design approved (gating condition)
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
5. **GDPR / AI processing**: Passing restaurant order data and customer dietary preferences to OpenAI's API — is this covered by the current DPA with OpenAI, and does it require customer disclosure in the privacy policy? Requires legal review before any customer-facing agent (especially #20 Customer Concierge) goes live.
6. **Review platform ingestion** (for #23 Reputation Agent): Does the platform currently receive Google/TripAdvisor reviews via API? If not, the Reputation Agent's `review.received` trigger is limited to in-app checkout ratings only in v1. Needs product confirmation.

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
| In-app star rating at checkout | Reputation & Feedback Agent (#23) | Required before #23 enters development | Open — confirm whether this exists |
| Review platform ingestion (Google/TripAdvisor API) | Reputation & Feedback Agent (#23) | Post-launch | Open |
| Discount/promo code system | Reputation & Feedback Agent (#23) | Required for "offer discount" action | Open — confirm whether this exists |
| `agent_domain_events` table | Agent Framework (#17) | Hard dependency for all agents | Specified in Agent Framework spec — new |
| Domain event emitters on existing models | Agent Framework (#17) | Hard dependency | Specified per agent — extend existing callbacks |
| `EmployeeRoleAudit` model | Employee Role Promotion (#29) | Hard dependency | New — specified in #29 spec |
| PostGIS availability in production | Nearby Menus Map (#32) | Must confirm before building spatial query service | Open — confirm with infra |
| Strikepay platform API model (marketplace vs standalone) | Strikepay Integration (#33) | Hard pre-development gate | Open — confirm with Strikepay BD before any dev |
| `OrdrChannel` subscription auth guard (verify DiningSession token before streaming) | Realtime Ordritem Tracking (#34) | Hard dependency — latent security risk regardless of feature | Open — confirm whether to address in Phase 1 of #34 or as a standalone security ticket; recommend Phase 1 |
| `Menuitem#default_station` column (kitchen vs bar) | Realtime Ordritem Tracking (#34) | Required before Phase 1 migration | Open — confirm assignment strategy (per-item at order time vs `Menuitem` default) |
| `calculated_price` vs `unit_price` column on Ordritem | Weight-Based Pricing (#31) | Affects migration design | Open — confirm exact column name in schema |
| Blog CMS implementation decision | mellow-menu-blog.md (marketing) | Engineering decision needed before build | Open — Rails ActionText vs headless CMS |
| AI feature landing pages (Sommelier, Whiskey Ambassador) | Marketing briefs | S-effort Rails views when marketing is ready | Open — awaiting marketing sign-off |
| Square Integration alpha testing completion | `backlog/square-integration.md` | High — in progress; Epics 1–6 done | Active — Epic 7 finalisation + Epic 8 alpha sign-off |
| Profit Margin Tracking Phase 4 | `backlog/35-menu-item-profit-margin-tracking.md` | Medium — feeds #14 Cost Insights | Ready for implementation; scope as part of #14 sprint |

---

## Key Architectural Decisions Made During Prioritisation

1. **QR Security before Auto Pay**: A `DiningSession` is a prerequisite for safe payment method capture. Security cannot be retrofitted after payment flows are live. Both are now completed.
2. **Branded emails before receipts**: The receipt mailer inherits the branded layout. Building them in sequence avoids rework. Both are now completed.
3. **Admin JWT before Partner Integrations**: Partner API endpoints require the JWT authentication layer that #8 provides.
4. **Heroku Inventory (#16) before Cost Publisher (#15) before Dynamic Pricing (#14)**: These three form a strict dependency chain. They cannot be built in parallel.
5. **MenuVersion system is fully built**: Confirmed via codebase inspection. Menu Experiments (#12) is unblocked — all dependencies resolved.
6. **R&D items explicitly excluded from sprint capacity** until launch blockers (#1–#7, all completed) and core post-launch revenue features (#8–#9) have shipped.
7. **Payments always via Orchestrator**: No direct Stripe/Square calls in any new feature. Square Integration follows this correctly via `Payments::SquareAdapter`.
8. **Admin cost tooling in `Admin::` namespace, never Madmin**: Confirmed across #14 and #15 specs.
9. **Agent Framework (#17) is a prerequisite for all agent work**: No individual agent ships before the framework's models, runner, toolbox, and approval UI are in place. Building agents on ad-hoc pipelines creates unmanageable technical debt.
10. **Agent Framework placed at #17, after CRM (#9 — done), JWT (#8 — done), and Smartmenu Theming (#10)**: CRM and JWT both delivered immediate revenue impact and are now complete. Theming (#10) is the current customer-facing priority. The agent tier is a post-launch competitive differentiator and should not consume capacity before theming and partner integrations (#11) ship.
11. **Service Operations Agent uses rule-based fast path for simple signals**: LLM calls for deterministic congestion thresholds (queue depth, stock levels) are wasteful. Reserve LLM calls for ambiguous multi-signal reasoning. This reduces cost and latency.
12. **No agent ever writes to live data without either auto-approval (per policy) or an explicit human confirmation**: This is a non-negotiable architectural principle across all agents. Enforced at the `Agents::PolicyEvaluator` and `Agents::ArtifactWriter` level, not just the UI.
13. **MCP Wrapper (#25) depends on both JWT (#8 — done) and Agent Framework (#17)**: The external MCP surface exposes the same toolbox that internal agents use. JWT is complete. Building MCP before the internal agent toolbox is proven would create a public API backed by unstable infrastructure. Do not start #25 until #17 is live and at least one Phase 1 agent has completed a full approval workflow run.
14. **Customer-facing agents (Concierge #20) require GDPR review before launch**: Passing dietary preference data to OpenAI's API in a customer-facing context requires legal sign-off. This is a hard pre-development gate for #20 specifically.
15. **Employee roles live on `Employee`, not `User`**: The Employee Role Promotion spec (#29) was corrected during refinement — roles (`staff/manager/admin`) are scoped per restaurant on the `Employee` model. Adding role columns to `User` would break the multi-restaurant model where one user can be staff at restaurant A and admin at restaurant B.
16. **Strikepay (#33) requires `Payments::Orchestrator` adapter, not direct API calls**: All third-party payment API calls go through the Orchestrator. A `Payments::StrikepayAdapter` must be created before any Strikepay API calls are made. The Strikepay platform API model (marketplace vs standalone accounts) must be confirmed before architecture is finalised. Do not start without this.
17. **Nearby Menus Map (#32) uses Stimulus, not React**: The raw spec proposed React components. All frontend work uses Hotwire (Turbo + Stimulus). The map provider JS SDK is wrapped in a Stimulus controller loaded lazily.
18. **Marketing/analysis documents are not dev specs**: Nine documents in `backlog/marketing/`, `backlog/competitor-analysis/`, and `marketing/` are strategy briefs and vendor evaluations. They have been dispositioned with classification headers but do not generate engineering tickets directly. The blog CMS and AI feature landing pages (S effort each) will enter the backlog as small engineering tickets when marketing is ready to execute.
19. **Square Integration is in-progress and tracked separately**: Epics 1–6 are complete. The integration uses `Payments::Orchestrator` / `Payments::SquareAdapter` correctly. It does not appear in the ranked priority table because it is under active development — progress is tracked via Epic 7 finalisation and Epic 8 alpha sign-off, not via sprint priority order.
20. **Profit Margin Tracking Phases 1–3 are built**: The `MenuitemCost` model, versioning, AI cost estimation, and basic reporting exist. Phase 4 (advanced analytics and AI recommendations integration) should be scoped as part of the Cost Insights (#15) sprint — the data it provides feeds the pricing model compiler.
21. **Smartmenu Theming (#10) uses CSS custom properties over `data-theme` attributes**: Themes extend the existing dark-mode pattern — each named theme is a `[data-theme="<name>"]` selector block overriding custom properties declared in `_smartmenu_mobile.scss`. No new CSS architecture, no new frontend framework. The `_smartmenu_mobile.scss` audit (extracting hard-coded values to custom properties) is the highest-risk task in the build.
