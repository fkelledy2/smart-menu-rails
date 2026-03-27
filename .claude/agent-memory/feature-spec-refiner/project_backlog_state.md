---
name: mellow.menu feature backlog state
description: Current state of the feature backlog after all March 2026 prioritisation passes — 31 ranked features total including 6 new post-launch product specs added 2026-03-24 (second pass)
type: project
---

Full spec refinement and prioritisation pass completed 2026-03-22. AI agent layer added 2026-03-24 (first pass): 8 new specs (Agent Framework + 7 individual agents). Six additional product specs refined 2026-03-24 (second pass): 2FA, Employee Role Promotion, Bulk Employee Invite, Weight-Based Pricing, Nearby Menus Map, Strikepay Integration. CRM Sales Funnel inserted at #9 on 2026-03-27 (third pass). Square Integration and Profit Margin Tracking classified and dispositioned on 2026-03-27 (fourth pass). Total backlog: 32 ranked features + 2 in-progress/partially-built items.

**Why:** Preparing the backlog for sprint execution — needed dev-ready specs and a clear priority order before engineering begins.

**How to apply:** Use PRIORITY_INDEX.md as the canonical source of truth for sprint planning. All launch blockers (#1–#7) are completed. Current focus: CRM Sales Funnel (#9) and JWT Token Management (#8) are the highest-value next items. AI agent tier (#16–#23) is post-launch and should not consume capacity until #8–#9 have shipped.

## COMPLETED — Launch Blockers + Enhancers
1. QR Code Security — COMPLETED 2026-03-24
2. Branded Email Styling — COMPLETED 2026-03-24
3. Branded Receipt Email — COMPLETED 2026-03-25
4. Auto Pay & Leave — COMPLETED 2026-03-25
5. Floorplan Dashboard — COMPLETED 2026-03-25
6. Pre-Configured Marketing QRs — COMPLETED 2026-03-25
7. Homepage Demo Booking & Video — COMPLETED 2026-03-26

## IN PROGRESS (not ranked — active development)
- Square Integration (Epics 1–6 complete; Epic 7 finalisation + Epic 8 alpha testing in progress)
- Menu Item Profit Margin Tracking (Phases 1–3 complete 2026-03-17; Phase 4 ready for implementation)

## Post-Launch: Product Features (current sprint targets)
8. JWT Token Management (API access for integrations)
9. CRM Sales Funnel — internal sales pipeline; directly drives restaurant acquisition
10. Partner Integrations (event-driven, workforce/CRM signals)
11. Menu Experiments (A/B testing) — all dependencies resolved
12. Table Wait Time Estimation
13. Dynamic Pricing Plans (cost-indexed, price-locked at signup)
14. Cost Insights + Pricing Model Publisher
15. Heroku Cost Inventory

## Post-Launch: AI Agent Tier (sequential build programme, all ranks shifted +1 from CRM insertion)
16. Agent Framework — shared infrastructure; prerequisite for all agents
17. Menu Import Agent — Phase 1; extends existing OcrMenuImport pipeline
18. Restaurant Growth Agent — Phase 1; weekly digest; read-only + advisory
19. Customer Concierge Agent — Phase 1; GDPR review required before dev
20. Menu Optimization Agent — Phase 2; executable change-set proposals
21. Service Operations Agent — Phase 2; rule-based fast path; agent_realtime queue
22. Reputation & Feedback Agent — Phase 2; all outbound requires manager approval
23. Staff Copilot Agent — Phase 2; most complex UX; ship last

## Post-Launch: Ecosystem
24. MCP AI Agent Wrapper — requires #8 JWT + #16 Framework
25. CDN Evaluation (deferred until traffic triggers)

## Post-Launch: New Product Features (ranks shifted +1 from CRM insertion)
27. Two-Factor Authentication — TOTP via rotp gem; Devise + Redis
28. Employee Role Promotion — Employee#role via EmployeeRoleAudit; NO role columns on User
29. Bulk Employee Invitation — extends StaffInvitation; CSV upload; Sidekiq delivery
30. Weight-Based Pricing — pricing_type enum on Menuitem; Stimulus weight selector
31. Nearby Menus Map — /discover page; Stimulus + Mapbox; PostGIS TBC
32. Strikepay Integration — hard pre-dev gate on Strikepay platform API model

## MenuVersion System — Confirmed Fully Built (2026-03-22)
Reference spec at docs/features/todo/features/menu-enhancements/menu-versioning-system.md. No new build required.

## Key Pre-Development Gates (as of 2026-03-27)
- AI Agent tier (#16–#23): LLM provider strategy, AgentPolicy self-service scope, audit log retention, PgBouncer status, GDPR DPA for #19, review platform ingestion for #22
- Strikepay (#32): platform API model (marketplace vs standalone) — HARD BLOCKER before any development
- PostGIS availability — affects Nearby Menus Map (#31) spatial query design
- Ordritem column name (`calculated_price` vs `unit_price`) — affects Weight-Based Pricing (#30) migration
