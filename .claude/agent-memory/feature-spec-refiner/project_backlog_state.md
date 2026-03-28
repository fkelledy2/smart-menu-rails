---
name: mellow.menu feature backlog state
description: Current state of the feature backlog after all March 2026 prioritisation passes — 33 ranked features total; sixth pass completed 2026-03-28 (rank alignment)
type: project
---

Full spec refinement and prioritisation pass completed 2026-03-22. AI agent layer added 2026-03-24 (first pass): 8 new specs (Agent Framework + 7 individual agents). Six additional product specs refined 2026-03-24 (second pass): 2FA, Employee Role Promotion, Bulk Employee Invite, Weight-Based Pricing, Nearby Menus Map, Strikepay Integration. CRM Sales Funnel inserted at #9 on 2026-03-27 (third pass). Square Integration and Profit Margin Tracking classified and dispositioned on 2026-03-27 (fourth pass). Smartmenu Theming inserted at #10 on 2026-03-28 (fifth pass), shifting all downstream items by +1. Sixth pass on 2026-03-28 aligned all 19 stale spec files to correct rank numbers. Total backlog: 33 ranked features + 2 in-progress/partially-built items.

**Why:** Preparing the backlog for sprint execution — needed dev-ready specs and a clear priority order before engineering begins.

**How to apply:** Use PRIORITY_INDEX.md as the canonical source of truth for sprint planning. All launch blockers (#1–#7), JWT (#8), and CRM (#9) are completed. Current focus: Smartmenu Theming (#10) is the highest-priority active item. Tracks B/C/D: Partner Integrations (#11), Menu Experiments (#12), Employee Role Promotion (#29 quick win). AI agent tier (#17–#24) is post-launch and should not consume capacity until #10–#12 have shipped.

## COMPLETED — Launch Blockers + Enhancers + Post-Launch
1. QR Code Security — COMPLETED 2026-03-24
2. Branded Email Styling — COMPLETED 2026-03-24
3. Branded Receipt Email — COMPLETED 2026-03-25
4. Auto Pay & Leave — COMPLETED 2026-03-25
5. Floorplan Dashboard — COMPLETED 2026-03-25
6. Pre-Configured Marketing QRs — COMPLETED 2026-03-25
7. Homepage Demo Booking & Video — COMPLETED 2026-03-26
8. JWT Token Management — COMPLETED 2026-03-27
9. CRM Sales Funnel — COMPLETED 2026-03-27

## IN PROGRESS (not ranked — active development)
- Square Integration (Epics 1–6 complete; Epic 7 finalisation + Epic 8 alpha testing in progress)
- Menu Item Profit Margin Tracking (Phases 1–3 complete 2026-03-17; Phase 4 ready for implementation)

## Current Sprint Targets (current next best actions as of 2026-03-28)
Track A: #10 Smartmenu Theming (M, no blockers, current #1 priority)
Track B: #11 Partner Integrations (M, JWT done — unblocked)
Track C: #12 Menu Experiments (M, all dependencies resolved)
Track D: #29 Employee Role Promotion (S, quick win — 3–5 days)

## Post-Launch: Product Features
10. Smartmenu Theming — CURRENT TOP PRIORITY
11. Partner Integrations (event-driven, workforce/CRM signals)
12. Menu Experiments (A/B testing) — all dependencies resolved
13. Table Wait Time Estimation
14. Dynamic Pricing Plans (cost-indexed, price-locked at signup)
15. Cost Insights + Pricing Model Publisher
16. Heroku Cost Inventory

## Post-Launch: AI Agent Tier (sequential build programme)
17. Agent Framework — shared infrastructure; prerequisite for all agents
18. Menu Import Agent — Phase 1; extends existing OcrMenuImport pipeline
19. Restaurant Growth Agent — Phase 1; weekly digest; read-only + advisory
20. Customer Concierge Agent — Phase 1; GDPR review required before dev
21. Menu Optimization Agent — Phase 2; executable change-set proposals
22. Service Operations Agent — Phase 2; rule-based fast path; agent_realtime queue
23. Reputation & Feedback Agent — Phase 2; all outbound requires manager approval
24. Staff Copilot Agent — Phase 2; most complex UX; ship last

## Post-Launch: Ecosystem
25. MCP AI Agent Wrapper — requires #8 JWT (done) + #17 Framework
26. CDN Evaluation (deferred until traffic triggers)

## Post-Launch: New Product Features
27. R&D Initiatives (Floor OS) — beyond sprint horizon
28. Two-Factor Authentication — TOTP via rotp gem; Devise + Redis
29. Employee Role Promotion — Employee#role via EmployeeRoleAudit; NO role columns on User
30. Bulk Employee Invitation — extends StaffInvitation; CSV upload; Sidekiq delivery
31. Weight-Based Pricing — pricing_type enum on Menuitem; Stimulus weight selector
32. Nearby Menus Map — /discover page; Stimulus + Mapbox; PostGIS TBC
33. Strikepay Integration — hard pre-dev gate on Strikepay platform API model

## MenuVersion System — Confirmed Fully Built (2026-03-22)
Reference spec at docs/features/todo/features/menu-enhancements/menu-versioning-system.md. No new build required.

## Key Pre-Development Gates (as of 2026-03-28)
- AI Agent tier (#17–#24): LLM provider strategy, AgentPolicy self-service scope, audit log retention, PgBouncer status, GDPR DPA for #20, review platform ingestion for #23
- Strikepay (#33): platform API model (marketplace vs standalone) — HARD BLOCKER before any development
- PostGIS availability — affects Nearby Menus Map (#32) spatial query design
- Ordritem column name (`calculated_price` vs `unit_price`) — affects Weight-Based Pricing (#31) migration

## Rank Alignment History
- Fifth pass (2026-03-28): Smartmenu Theming inserted at #10, all items from #11 onward shifted +1
- Sixth pass (2026-03-28): All 19 spec files with stale rank numbers updated to match PRIORITY_INDEX
  - Updated: partner-integrations (#10→#11), menu-experiments (#11→#12), table-wait-time (#12→#13), dynamic-pricing (#13→#14), cost-insights (#14→#15), heroku-cost (#15→#16), agent-framework (#16→#17), 7 individual agent specs (#17–#23 → #18–#24), mcp-wrapper (#24→#25), cdn-evaluation (#25→#26), 2fa (#27→#28), employee-role-promotion (#28→#29), bulk-employee-invite (#29→#30), weight-based-pricing (#30→#31), nearby-menus-map (#31→#32), strikepay (#32→#33)
