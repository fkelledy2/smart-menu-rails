# UI / UX Consistency Overhaul

## Overview
This document proposes a UI/UX consistency overhaul with the goals of:
- [ ] **Consistency**: the same user intent produces the same UI patterns across the app.
- [ ] **Maintainability**: a small set of reusable primitives (styles + view components + JS behaviors) that are easy to apply and hard to regress.

This plan targets:
1. Common functions implemented with different UI/UX designs.
2. Inconsistent colour coding for buttons/badges/dropdowns/selects.
3. A consistent approach for row-level “active/inactive” visualization.
4. Consistency of navigation patterns.
5. Dead pages (no longer linked from core flows).
6. Orphaned content (partials/assets/routes not used).
7. Non-localised content.

## Current Observations (from codebase signals)

### Multiple UI systems exist; we should converge on one
- There is a 2025 design system (`app/assets/stylesheets/design_system_2025.scss`) and shared 2025 partials.
- There is also widespread Bootstrap usage (`btn btn-*`, `badge bg-*`, Bootstrap dropdowns).

**Decision:** unify on **Bootstrap** as the long-term source of truth, so we can overlay a Bootstrap theme in the future.

### Multiple styling systems are being mixed
Repo scans show usage of:
- Bootstrap patterns: `btn btn-*`, `badge bg-*` in many views.
- 2025 patterns: `btn-2025`, `badge-2025`, `content-card-2025`, `form-control-2025` across many other views.

This mix is the main source of:
- inconsistent colour semantics (e.g. “danger” may look different depending on old/new classes)
- inconsistent spacing/density
- inconsistent affordances (row click vs explicit links vs action menus)

### Navigation is already converging in key areas
- Restaurant and Menu 2025 sidebars use Turbo frames (`restaurant_content`, `menu_content`) and consistent sidebar link patterns.
- Clickable rows are centralized via a JS handler (`app/javascript/restaurants.js`) that avoids navigating when clicking interactive elements.

## Overarching Strategy

### 1) Establish a “Source of Truth” for UI primitives
Pick and codify a single set of primitives for:
- [ ] Buttons
- [ ] Badges/status chips
- [ ] Dropdown action menus
- [ ] Forms/selects
- [ ] List rows (desktop + mobile)
- [ ] Empty states
- [ ] Confirmation UX

**Decision:** treat **Bootstrap** as the source of truth.

Implication:
- [ ] In `*_2025` surfaces, progressively replace `btn-2025`, `badge-2025`, `form-control-2025`, and ad-hoc inline CSS with:
  - [ ] Bootstrap button variants (`btn`, `btn-primary`, `btn-outline-secondary`, `btn-danger`, etc.)
  - [ ] Bootstrap badges (`badge text-bg-*` / `badge bg-*` depending on Bootstrap version in this app)
  - [ ] Bootstrap form controls
  - [ ] Bootstrap dropdown/action patterns

### 2) Build a small UI kit in Rails primitives (not ad-hoc CSS)
Prefer:
- [ ] Shared partials (`shared/_*.html.erb`) for visual components
- [ ] Helper methods for common patterns (e.g. `status_badge`, `primary_button`, `danger_button`)
- [ ] A small number of Stimulus controllers for behaviors (bulk select, sortable, clickable-row)

Avoid:
- [ ] Inline `<style>` blocks in views for reusable patterns
- [ ] Creating new one-off class systems that diverge from Bootstrap

### 3) Roll out incrementally by “surface area”
**Decision on sequencing:**
- [ ] `restaurants/edit_2025` (and all `restaurants/sections/_*_2025`)
- [ ] `menus/edit_2025` (and all `menus/sections/_*_2025`)
- [ ] Customer SmartMenu flows

## Standards to Define (Design Contract)

### Buttons
Define a strict mapping of intent → class (Bootstrap):
- [ ] **Primary CTA**: `btn btn-primary`
- [ ] **Secondary**: `btn btn-outline-secondary` (or `btn btn-secondary` where needed)
- [ ] **Ghost/tertiary**: `btn btn-link` (or `btn btn-outline-secondary` as a consistent “quiet” default)
- [ ] **Destructive**: `btn btn-danger` or `btn btn-outline-danger`

Rules:
- [ ] Destructive actions should not be “primary” by default.
- [ ] Use one consistent confirmation mechanism (Turbo confirm or modal) by context.

### Badges / status chips
Standardize on Bootstrap badges.

Plan:
- [ ] Replace `shared/_status_badge_2025` with a Bootstrap-based status badge helper/partial (or introduce a new `shared/_status_badge` and migrate call sites).
- [ ] Ensure all domain statuses map consistently to Bootstrap semantic variants.

### Dropdown actions
Standardize row-level actions:
- [ ] Use a single pattern: 3-dots or “Actions” dropdown.
- [ ] For bulk actions: an “Actions” dropdown that enables when any selection is made.

### Row-level active/inactive visualization
Use existing `.row-status-*` classes consistently:
- [ ] `row-status-active`
- [ ] `row-status-inactive`
- [ ] `row-status-archived`

Rules:
- [ ] Row color should reflect *state*, not *category*.
- [ ] Status badge should reflect *state* as text.
- [ ] Avoid using opacity alone (accessibility); rely on background + badge.

### Navigation consistency
Define when to use:
- [ ] **Clickable row** navigation (list/table rows)
- [ ] **Explicit primary link** (chevron button)
- [ ] **Open in new tab** behaviors

Rules:
- [ ] Clickable rows must not interfere with selecting checkboxes, drag handles, or dropdown actions.
- [ ] For Turbo frames, keep `data-turbo-frame` consistent within a surface.

## Audit Plan (what to find and how)

### A) Common functions with different UI/UX designs
Inventory these “same intent, different UI” areas:
- [ ] Bulk selection + bulk actions
- [ ] Row actions (trash icon vs kebab vs chevron)
- [ ] Create/new flows
- [ ] Empty states
- [ ] Confirmations
- [ ] Tabs vs sidebars vs stacked sections

Deliverable:
- [ ] A matrix: *Function* → *Screens* → *Patterns used* → *Target pattern*

### B) Colour coding inconsistencies
Audit:
- [ ] Buttons: where `btn btn-danger` vs `btn-2025-outline-danger` is used
- [ ] Badges: `badge bg-success` vs `badge-2025-success`
- [ ] Selects: Bootstrap selects vs TomSelect vs 2025 controls

Deliverable:
- [ ] A mapping doc: intent → allowed classes/components
- [ ] A refactor list: top offenders + fixes

### C) Row-level active/inactive
Audit all list/table rows that represent an entity with a state.
- [ ] Ensure row has `row-status-*` class.
- [ ] Ensure status badge matches.

Deliverable:
- [ ] A checklist per major list screen

### D) Navigation consistency
Audit:
- [ ] Sidebars
- [ ] “Back” buttons
- [ ] “View” vs “Edit” link destinations
- [ ] Turbo frame usage (full-page vs frame)

Deliverable:
- [ ] Navigation rules + a list of inconsistent pages

### E) Dead pages
Definition: reachable by URL/route but not linked from core navigations.

Process:
- [ ] Enumerate core nav entry points:
  - [ ] Restaurant sidebar 2025
  - [ ] Menu sidebar 2025
  - [ ] Main dashboard/home
  - [ ] Onboarding
  - [ ] Staff dashboards
- [ ] Compare against `rails routes` output.

Deliverable:
- [ ] List of routes/controllers that are not reachable from core nav
- [ ] Decide: delete, hide behind admin, or re-link

### F) Orphaned content
Definition: files/partials/assets referenced nowhere.

Process:
- [ ] Identify partials under `app/views/**/_*.erb*` with zero references.
- [ ] Identify JS/CSS bundles not imported.

Deliverable:
- [ ] Candidate removal list + risk assessment

### G) Non-localised content
Definition: visible user text not using `t(...)`.

Process:
- [ ] Prioritize 2025 surfaces first.
- [ ] Then expand to onboarding + smartmenu.

Deliverable:
- [ ] A backlog of hardcoded strings with file/line references
- [ ] Decide translation key structure (by feature/namespace)

## Implementation Roadmap (Phased)

### Phase 0 — Decide and document standards (1–2 days)
- [ ] Finalize “source of truth” primitives (Bootstrap).
- [ ] Write a short set of rules:
  - [ ] buttons
  - [ ] badges
  - [ ] dropdown actions
  - [ ] row states
  - [ ] navigation
  - [ ] localization requirements

### Phase 1 — Quick wins + guardrails (2–5 days)
- [ ] Create/extend shared primitives:
  - [ ] Introduce a Bootstrap-based `shared/_status_badge` (or helper) and migrate the most common call sites.
  - [ ] Create a shared “actions dropdown” partial for consistent menus (Bootstrap dropdown markup).
- [ ] Add automated checks:
  - [ ] CI check: flag `btn-2025` and `badge-2025` usage in `*_2025` views (new work should not add more).
  - [ ] CI check: heuristic scan for hardcoded strings in `*_2025` views.

### Phase 2 — Converge `restaurants/edit_2025` (1–2 weeks)
- [ ] Ensure all restaurant sections use consistent list rows, badges, actions, empty states.
- [ ] Replace `btn-2025`/`badge-2025` patterns with Bootstrap equivalents.

### Phase 3 — Converge `menus/edit_2025` (1–2 weeks)
- [ ] Same work as Phase 2, but for menu editing surfaces.

### Phase 3 — Converge onboarding + auth (1 week)
- [ ] Devise and onboarding flows:
  - [ ] unify button styles
  - [ ] unify form controls
  - [ ] localize remaining content

### Phase 4 — Customer SmartMenu flows + staff dashboards (1–2 weeks)
- [ ] Standardize action bars, modals, and status indications.
- [ ] Align status colors with the 2025 semantic palette.

### Phase 5 — Dead/orphan cleanup (ongoing)
- [ ] Remove or archive unused pages/routes.
- [ ] Delete orphaned partials/assets.

## Success Criteria
- [ ] A developer can implement a new list screen without inventing new CSS.
- [ ] A user sees consistent button meanings across the app.
- [ ] All “status” displays use the same badge component and same semantic colors.
- [ ] 2025 surfaces have near-zero usage of `btn btn-*` and `badge bg-*`.
- [ ] New user-visible strings are localized by default.

## Open Questions (to confirm before executing)
- [ ] **Bootstrap version:** are we on Bootstrap 4 or 5? (This matters for badges: `badge bg-*` vs `badge text-bg-*`, and for some utility class names.)
- [ ] **Theme strategy:** do you envision a single theme (brand), or per-restaurant themes?
- [ ] **Accessibility requirements:** do we need to meet a specific standard (e.g. WCAG AA) as part of this overhaul?
- [ ] **Localization:** what locales should we treat as officially supported, and do we want to add tooling to prevent regressions (e.g. i18n-tasks)?
- [ ] **Definition of “dead pages”:** what counts as “core accessible pages” in your product (dashboard + sidebars + onboarding only)?
- [ ] **Rollout approach:** can we make breaking visual changes behind a feature flag, or do you prefer direct refactors?
