---
name: mellow.menu feature backlog state
description: Current state of the feature backlog after March 2026 prioritisation passes, including AI agent tier addition (2026-03-24)
type: project
---

Full spec refinement and prioritisation pass completed 2026-03-22. AI agent layer added 2026-03-24: 8 new specs (Agent Framework + 7 individual agents). Total backlog: 25 ranked features across 7 categories.

**Why:** Preparing the backlog for sprint execution — needed dev-ready specs and a clear priority order before engineering begins.

**How to apply:** Use PRIORITY_INDEX.md as the canonical source of truth for sprint planning. Never skip ahead to post-launch items while launch blockers remain open. The AI agent tier (#15–#22) is explicitly post-launch and should not consume capacity until blockers #1–#3 and enhancers #4–#5 have shipped.

## Launch Blockers (must ship before first live restaurant)
1. QR Code Security — rotating tokens, DiningSession model, order-mutation session gate, Rack::Attack throttles, admin QR regeneration
2. Branded Email Styling — shared branded mailer layout for all outgoing emails
3. Branded Receipt Email — staff-initiated and customer self-service receipt delivery after payment

## Launch Enhancers (high-value but not blocking)
4. Auto Pay & Leave — customer payment on file + auto-capture on bill request
5. Floorplan Dashboard — real-time table status grid for staff
6. Pre-Configured Marketing QRs — decouple print production from menu deployment
7. Homepage Demo Booking & Video — minimum viable sales funnel

## Post-Launch: Product Features
8. JWT Token Management (API access for integrations)
9. Partner Integrations (event-driven, workforce/CRM signals)
10. Menu Experiments (A/B testing) — MenuVersion dependency RESOLVED
11. Table Wait Time Estimation
12. Dynamic Pricing Plans (cost-indexed, price-locked at signup)
13. Cost Insights + Pricing Model Publisher
14. Heroku Cost Inventory

## Post-Launch: AI Agent Tier (sequential build programme)
15. Agent Framework — shared infrastructure; prerequisite for all agents
    - 7 new models: AgentWorkflowRun, AgentWorkflowStep, AgentArtifact, AgentApproval, AgentPolicy, ToolInvocationLog, AgentDomainEvent
    - 6 core services in app/services/agents/
    - 5 Sidekiq queues: agent_critical, agent_realtime, agent_high, agent_default, agent_low
    - AI Workbench UI at /restaurants/:id/agent_workbench
    - Flipper flag: agent_framework (master switch)
16. Menu Import Agent — Phase 1; extends existing OcrMenuImport pipeline; highest onboarding value
17. Restaurant Growth Agent — Phase 1; weekly digest; read-only + advisory; lowest risk first agent
18. Customer Concierge Agent — Phase 1; customer-facing NL discovery; streaming LLM; GDPR review required
19. Menu Optimization Agent — Phase 2; structured change-set proposals; executable (with approval)
20. Service Operations Agent — Phase 2; real-time kitchen ops; rule-based fast path; agent_realtime queue
21. Reputation & Feedback Agent — Phase 2; post-dining signals; all outbound requires manager approval
22. Staff Copilot Agent — Phase 2; NL back-office interface; most complex UX integration; ship last

## Post-Launch: Ecosystem
23. MCP AI Agent Wrapper — previously #15; renumbered; requires #8 JWT + #15 Framework
24. CDN Evaluation (deferred until traffic triggers)

## R&D Items (not sprint-ready)
All items in r_and_d/ directory. Horizon 1 (currently feasible): Table Digital Twin, Ultra-Low Latency Runtime, Recommendation Graph, Context-Aware Menus, Social Dining Intelligence, Staff Assistance, Presence/Identity, Voice Ordering, Distributed Operating Surface.

## MenuVersion System — Confirmed Fully Built (2026-03-22)
app/models/menu_version.rb, four services, controller, DB schema, and tests all exist. Reference spec at docs/features/todo/features/menu-enhancements/menu-versioning-system.md. No new build required.

## AI Agent Pre-Development Gates (unresolved as of 2026-03-24)
- LLM provider strategy (OpenAI-only vs provider-agnostic from start)
- AgentPolicy self-service UI scope
- Audit log retention period (recommend 90 days — needs legal/compliance)
- PgBouncer active in production? (affects domain event dispatch approach)
- GDPR / AI processing DPA coverage — critical blocker for #18 Customer Concierge
- Google/TripAdvisor review ingestion — scopes #21 Reputation Agent to in-app signals only until resolved
