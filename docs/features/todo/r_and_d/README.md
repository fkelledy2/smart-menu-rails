# Restaurant Floor OS — R&D Initiative Index

## Status
Research / Strategy — All items in this directory are R&D bets, not development-ready specs. None are launch blockers. They inform the product vision and should be promoted to the main features backlog when ready for scoping.

## Priority within R&D
From the master `PRIORITY_INDEX.md` perspective, R&D items collectively rank beyond #33 and should not consume sprint capacity until at minimum Smartmenu Theming (#10), Partner Integrations (#11), and Menu Experiments (#12) have shipped. See `PRIORITY_INDEX.md` for the current canonical rank table.

## Recommended Build Sequence (within R&D horizon)

### Horizon 1 — Build First (Software-only, no hardware dependency)
These are the highest-leverage R&D initiatives that can be started while the core product matures:

| Initiative | File | Rationale |
|---|---|---|
| Table Digital Twin & State Machine | `currently-feasible/table-digital-twin-and-state-machine-layer.md` | Foundation for most other R&D epics |
| Ultra-Low Latency Menu Runtime | `currently-feasible/ultra-low-latency-menu-runtime.md` | Benefits every other feature |
| Recommendation & Taste Graph | `currently-feasible/recommendation-and-taste-graph.md` | Revenue-enhancing, data compounds |
| Context-Aware Adaptive Menus | `currently-feasible/context-aware-adaptive-menus.md` | Differentiation from commodity tools |
| Social Dining Intelligence | `currently-feasible/social-dining-intelligence.md` | Conversion lift, low privacy risk |
| Staff Assistance & Proximity Response | `currently-feasible/staff-assistance-and-proximity-response.md` | Operational value, clear MVP |
| Presence, Identity & Return-Guest Warm Start | `currently-feasible/presence-identity-and-return-guest-warm-start.md` | Retention, performance |
| Conversational & Voice Ordering | `currently-feasible/conversational-and-voice-ordering.md` | Accessibility, differentiation |
| Distributed Restaurant Operating Surface | `currently-feasible/distributed-restaurant-operating-surface.md` | Platform unification |

### Horizon 2 — Controlled Experiments (some hardware/platform constraints)
- `partially-feasible/proximity-aware-table-context.md`
- `partially-feasible/collaborative-dining-mesh.md`
- `partially-feasible/personal-ai-dining-assistant.md`
- `partially-feasible/kitchen-aware-commercial-optimization.md`
- `partially-feasible/ambient-sensing-and-restaurant-state-detection.md`
- `partially-feasible/cross-table-social-and-commerce-layer.md`
- `partially-feasible/edge-intelligence-and-resilient-local-compute.md`

### Horizon 3 — Moonshots (requires external tech advancement)
- `requires-external-advancement/uwb-table-detection.md`
- `requires-external-advancement/browser-native-local-mesh-networking.md`
- `requires-external-advancement/nearby-menu-propagation.md`

### Deprioritised / Nah
- `nah/crowd-sourced-menu-media-graph.md` — valuable long-term but requires significant moderation infrastructure; deprioritised until core product is stable.
- `nah/interactive-dining-entertainment-layer.md` — nice-to-have, venue-type-specific; post-launch.
- `nah/camera-driven-recognition-and-reorder-flows.md` — high complexity, low breadth; post-launch.

## Notes
- The original high-level roadmap is in `restaurant-floor-os-r-and-d-roadmap.md`.
- These initiative files are intended to make each R&D bet easier to discuss and prioritise. They should be promoted to development-ready specs (using the standard template) before entering the sprint backlog.
- Smart table entry points (NFC) from `currently-feasible/smart-table-entry-points.md` are closely related to QR Security (#1) and can be scoped as a fast-follow enhancement once Phase 1 QR security ships.
