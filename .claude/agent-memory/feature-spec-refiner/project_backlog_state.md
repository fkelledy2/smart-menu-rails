---
name: mellow.menu feature backlog state
description: Current state of the feature backlog after full spec refinement and prioritisation pass (March 2026), including MenuVersion discovery revision
type: project
---

Full spec refinement and prioritisation pass completed 2026-03-22. 41 feature files across 7 categories were analysed and rewritten/enhanced. A MenuVersion system discovery pass was completed on the same date, resolving the previously-flagged "unbuilt dependency" gap.

**Why:** Preparing the backlog for sprint execution — needed dev-ready specs and a clear priority order before engineering begins.

**How to apply:** Use PRIORITY_INDEX.md as the canonical source of truth for sprint planning. Never skip ahead to post-launch items while launch blockers remain open.

## Launch Blockers (must ship before first live restaurant)
1. QR Code Security — rotating tokens, DiningSession model, order-mutation session gate, Rack::Attack throttles, admin QR regeneration
2. Branded Email Styling — shared branded mailer layout for all outgoing emails
3. Branded Receipt Email — staff-initiated and customer self-service receipt delivery after payment

## Launch Enhancers (high-value but not blocking)
4. Auto Pay & Leave — customer payment on file + auto-capture on bill request
5. Floorplan Dashboard — real-time table status grid for staff
6. Pre-Configured Marketing QRs — decouple print production from menu deployment
7. Homepage Demo Booking & Video — minimum viable sales funnel

## Post-Launch (important, not blocking)
8. JWT Token Management (API access for integrations)
9. Partner Integrations (event-driven, workforce/CRM signals)
10. Menu Experiments (A/B testing) — ELEVATED from #14; MenuVersion dependency is RESOLVED (system is fully built)
11. Table Wait Time Estimation
12. Dynamic Pricing Plans (cost-indexed, price-locked at signup)
13. Cost Insights + Pricing Model Publisher
14. Heroku Cost Inventory
15. MCP AI Agent Wrapper
16. CDN Evaluation (deferred until traffic triggers)

## MenuVersion System — Confirmed Fully Built
Previously flagged as "unbuilt hard dependency" for Menu Experiments. Confirmed via codebase inspection that the following all exist and are production-ready:
- `app/models/menu_version.rb` — immutable snapshot model
- `app/services/menu_version_snapshot_service.rb` — jsonb snapshot creation
- `app/services/menu_version_diff_service.rb` — section/item diff
- `app/services/menu_version_activation_service.rb` — immediate + windowed activation
- `app/services/menu_version_apply_service.rb` — in-memory snapshot projection (rollback preview)
- `app/controllers/menus/versions_controller.rb` — list, diff, create_version, activate_version endpoints
- `db/schema.rb` — `menu_versions` table with all required columns and indexes
- Comprehensive test coverage in both `spec/` and `test/`
- Reference spec created at: `docs/features/todo/features/menu-enhancements/menu-versioning-system.md`

Menu Experiments only needs QR Security (#1) to ship first (for the DiningSession model). It no longer has a dependency on unbuilt infrastructure.

## R&D Items (not sprint-ready)
All items in r_and_d/ directory. Horizon 1 (currently feasible, software-only): Table Digital Twin, Ultra-Low Latency Runtime, Recommendation Graph, Context-Aware Menus, Social Dining Intelligence, Staff Assistance, Presence/Identity, Voice Ordering, Distributed Operating Surface.
