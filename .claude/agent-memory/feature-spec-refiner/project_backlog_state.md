---
name: mellow.menu feature backlog state
description: Current state of the feature backlog after all March 2026 prioritisation passes — 38 ranked features total; fifteenth pass completed 2026-03-31 (Smartmenu Preview Modes #36 confirmed COMPLETED)
type: project
---

Full spec refinement and prioritisation pass completed 2026-03-22. AI agent layer added 2026-03-24 (first pass): 8 new specs (Agent Framework + 7 individual agents). Six additional product specs refined 2026-03-24 (second pass): 2FA, Employee Role Promotion, Bulk Employee Invite, Weight-Based Pricing, Nearby Menus Map, Strikepay Integration. CRM Sales Funnel inserted at #9 on 2026-03-27 (third pass). Square Integration and Profit Margin Tracking classified and dispositioned on 2026-03-27 (fourth pass). Smartmenu Theming inserted at #10 on 2026-03-28 (fifth pass). Sixth pass on 2026-03-28 aligned all 19 stale spec files. Naked Domain Strategy added as IQ-1 (eleventh pass, 2026-03-30). Realtime Ordritem Tracking added at #34 (twelfth pass, 2026-03-30). Thirteenth pass on 2026-03-30 refined the final 5 unrefined specs: Square Integration (IN-PROGRESS), Profit Margin Phase 4 (#35), Smartmenu Preview Modes (#36), AI Sommelier Landing Page (#37), AI Whiskey Ambassador Landing Page (#38). Fifteenth pass 2026-03-31: Smartmenu Preview Modes (#36) confirmed COMPLETED — SmartmenuPreviewToken live and tested, staff-mode-indicator removed, ?view=staff fully retired.

**Why:** Preparing the backlog for sprint execution — needed dev-ready specs and a clear priority order before engineering begins.

**How to apply:** Use PRIORITY_INDEX.md as the canonical source of truth for sprint planning. All launch blockers (#1–#7), JWT (#8), CRM (#9), Smartmenu Theming (#10), Partner Integrations (#11), Menu Experiments (#12), Table Wait Time (#13), and Smartmenu Preview Modes (#36) are completed. Current immediate actions: (1) IQ-1 Naked Domain, (2) complete Square Integration remaining 3 items + alpha, (3) Tracks A/B/C/D for product work (Track E retired — #36 shipped).

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
10. Smartmenu Theming — COMPLETED 2026-03-28
11. Partner Integrations (Event-Driven) — COMPLETED 2026-03-29
12. Menu Experiments (A/B Testing) — COMPLETED 2026-03-29
13. Table Wait Time Estimation — COMPLETED 2026-03-29
36. Smartmenu Preview Modes — COMPLETED 2026-03-31 (SmartmenuPreviewToken live; staff-mode-indicator removed; ?view=staff retired)

## INFRASTRUCTURE QUICK WIN
IQ-1: Naked Domain Canonical Strategy (S — Rack initializer + DNS + robots.txt; ship before public launch; NOT YET DONE as of 2026-03-31)

## IN PROGRESS (not ranked — active development)
- Square Integration (Epics 1–8 backend/UI complete; 3 remaining: split-bill progress UI, degraded-status email, Reconnect CTA; then alpha testing)
- Menu Item Profit Margin Tracking (Phases 1–3 complete 2026-03-17; Phase 4 ranked at #35)

## Current Sprint Targets (next best actions as of 2026-03-31)
Pre-sprint: IQ-1 Naked Domain (afternoon's work — NOT YET DONE)
Parallel: Square Integration — complete 3 remaining items, begin alpha
Track A: #14 Dynamic Pricing Plans (L, depends on #15 + #16)
Track B: #16 Heroku Cost Inventory then #15 Cost Insights (unlocks #14)
Track C: #28 Two-Factor Authentication (M, security hardening)
Track D: #29 Employee Role Promotion (S, quick win — 3–5 days)
Track E: RETIRED — #36 Smartmenu Preview Modes COMPLETED 2026-03-31

## Post-Launch: Product Features
14. Dynamic Pricing Plans (cost-indexed)
15. Cost Insights + Pricing Model Publisher
16. Heroku Cost Inventory
35. Profit Margin Tracking Phase 4 (menu engineering matrix + AI pricing recs + bundling)

## Post-Launch: AI Agent Tier (sequential build programme)
17. Agent Framework — shared infrastructure; prerequisite for all agents
18. Menu Import Agent — Phase 1; extends existing OcrMenuImport pipeline
19. Restaurant Growth Agent — Phase 1; weekly digest; read-only + advisory
20. Customer Concierge Agent — Phase 1; GDPR review required before dev
21. Menu Optimization Agent — Phase 2; feeds from Profit Margin Phase 4 output
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
34. Realtime Ordritem Tracking — fulfillment_status column + batch station actions

## Post-Launch: Marketing Pages
37. AI Sommelier Landing Page (S — Rails view; gated on feature live + copy/design ready)
38. AI Whiskey Ambassador Landing Page (S — same pattern as #37; downstream of it)

## MenuVersion System — Confirmed Fully Built (2026-03-22)
Reference spec at docs/features/todo/features/menu-enhancements/menu-versioning-system.md. No new build required.

## Key Pre-Development Gates (as of 2026-03-31)
- IQ-1 Naked Domain: not yet implemented; no Rack middleware found in config/initializers/; sitemap.rb still references www.mellow.menu as default host
- Square Integration alpha: requires deployed sandbox environment; 3 remaining items (split-bill progress UI, degraded-status email, Reconnect CTA)
- AI Agent tier (#17–#24): LLM provider strategy, AgentPolicy self-service scope, audit log retention, PgBouncer status, GDPR DPA for #20, review platform ingestion for #23
- Strikepay (#33): platform API model (marketplace vs standalone) — HARD BLOCKER before any development
- PostGIS availability — affects Nearby Menus Map (#32) spatial query design
- Profit Margin Phase 4 (#35) open questions: bundle suggestion threshold, dashboard vs new tab for bundling UI, Flipper flag additive vs replacing

## Rank Alignment History
- Fifteenth pass (2026-03-31): Smartmenu Preview Modes (#36) confirmed COMPLETED. SmartmenuPreviewToken model live at app/models/smartmenu_preview_token.rb with tests. Controller uses params[:preview] decode. staff-mode-indicator removed from all views. ?view=staff retired immediately (no grace period). Track E retired from sprint recommendation. PRIORITY_INDEX updated: #36 row struck through in master table, completion note added to notes section, sprint recommendation updated.
- Thirteenth pass (2026-03-30): 5 new specs refined. Square Integration (IN-PROGRESS, status updated). Profit Margin Phase 4 (#35, M, Post-Launch). Smartmenu Preview Modes (#36, S, Launch Enhancer). AI Sommelier Landing Page (#37, S, Post-Launch/Marketing). AI Whiskey Ambassador Landing Page (#38, S, Post-Launch/Marketing). PRIORITY_INDEX updated with all 5 entries, sprint recommendation expanded with Track E (Preview Modes), and dependencies graph extended.
- Twelfth pass (2026-03-30): Realtime Ordritem Tracking added at #34.
- Eleventh pass (2026-03-30): Naked Domain Canonical Strategy added as IQ-1.
- Fifth pass (2026-03-28): Smartmenu Theming inserted at #10, all items from #11 onward shifted +1.
- Sixth pass (2026-03-28): All 19 spec files with stale rank numbers updated to match PRIORITY_INDEX.
