# UI/UX Unified Specification — mellow.menu

> **Status:** In Progress
> **Date:** 2026-03-02
> **Supersedes:** `ui-ux-upgrade-spec.md` + `uiuxoverhaul.md` (merged)
> **Author:** Cascade + FK

---

## 1. Purpose

This document merges the **UI/UX Upgrade Spec** (flow-by-flow redesign) and the **UI/UX Consistency Overhaul** (CSS convergence & audit plan) into a single source of truth. It lists everything already delivered and all remaining work, organised by priority.

---

## 2. Design Principles

1. **Mobile-first** — every screen starts at 375px, then scales up.
2. **Bootstrap is the source of truth** — no new `*-2025` class systems; progressively replace existing ones with Bootstrap equivalents.
3. **Progressive disclosure** — show only what's needed; advanced options behind expandable sections.
4. **Consistent interaction vocabulary** — same gesture/pattern for the same intent everywhere (7 canonical patterns).
5. **Performance budget** — smartmenu pages: LCP <1.2s, INP <100ms, CLS <0.05.
6. **Testability by design** — every interactive element has `data-testid`.
7. **Accessibility** — WCAG 2.2 AA minimum; touch targets >=44px; focus-visible on all interactables.
8. **Localisation by default** — all user-facing strings use `t(...)`.

---

## 3. What Has Been Delivered

### 3.1 Foundation (Phase 1 — complete)

| Item | Status |
|---|---|
| `view_component` gem added | Done |
| `StatusBadgeComponent` | Done |
| `EmptyStateComponent` + template | Done |
| `GoLiveChecklistComponent` + template | Done |
| `_bottom_sheet.html.erb` + `bottom_sheet_controller.js` | Done |
| `_mobile_tab_bar.html.erb` + `mobile_tab_bar_controller.js` | Done |
| `tab_bar_controller.js` | Done |
| `_skeleton_frame.html.erb` + `_skeleton_frame.scss` | Done |
| `_inline_save_indicator.html.erb` | Done |
| `auto_save_controller.js` | Done |
| Design tokens (motion, breakpoints, touch targets, dark mode) in `design_system_2025.scss` | Done |
| `data-testid` comprehensive pass across all flows | Done |
| Lighthouse CI job + `lighthouse-budget.json` | Done |
| ViewComponent unit tests (4 files) | Done |

### 3.2 Restaurant & Menu Management (Phase 3 — mostly complete)

| Item | Status |
|---|---|
| Mobile bottom tab bar on restaurant edit | Done |
| Turbo frame skeleton loading (CSS shimmer bar) | Done |
| AI image generator extracted to `ai_image_generator_controller.js` | Done |
| AI progress/polish/localize extracted to `ai_progress_controller.js` (~418 lines removed from `menus/edit_2025.html.erb`) | Done |
| Drag-to-reorder via `sortable_controller.js` (sections + items) | Done |
| Inline click-to-edit via `inline_edit_controller.js` (name/price) | Done |
| Breadcrumb on restaurant edit (Home > Restaurants > Name) | Done |
| Auto-save Stimulus controller | Done |

### 3.3 Smart Menu Customer (Phase 4 — performance wins)

| Item | Status |
|---|---|
| Client-side menu search (`menu_search_controller.js`) | Done |
| Section sticky tabs (`section_tabs_controller.js`, IntersectionObserver) | Done |
| List layout as default (`menu_layout_controller.js`) | Done |
| Cart bottom sheet wired (`_cart_bottom_sheet.html.erb`) | Done |
| Footer removed for customer smartmenu | Done |
| Skeleton loading wired in `show.html.erb` | Done |
| Lazy Stripe.js (`lazy_stripe_controller.js`) | Done |
| Cart badge controller with bounce animation | Done |
| Welcome banner converted to Stimulus (`welcome_banner_controller.js`) | Done |
| Micro-animations (cart badge bounce + add button scale) | Done |
| WebP image derivatives (60-95% size reduction) | Done |
| LQIP blur-up placeholders (20px WebP q20 derivative) | Done |
| Font Awesome conditionally loaded (~90KB saved on customer pages) | Done |
| Stripe.js deferred (non-render-blocking) | Done |
| Broadcast latency fix (8 partial renders removed, 200-500ms -> 5-10ms) | Done |
| 4 composite DB indexes for smartmenu queries | Done |

### 3.4 Other Completed Items

| Item | Status |
|---|---|
| Duplicate `class` attribute fixes (96 instances across `show.html.erb`, `menus/show.html.erb`, `tracks/show.html.erb`) | Done |
| Duplicate `class` fix in `_showMenuContentStaff.html.erb` | Done |
| Dark mode CSS token overrides in `design_system_2025.scss` + component SCSS | Done |
| Inline `<script>` removed from `menus/edit_2025.html.erb` | Done |
| Dead code cleanup phases 1-4 (orphaned views, helpers, jobs, services, model, Stimulus controllers, ViewComponents, serializers, gems, policies, tests) | Done |

---

## 4. Remaining Work — Prioritised

### Priority 1: Bootstrap Convergence & UI Standards (from overhaul spec)

> These items establish the visual consistency rules that all subsequent work must follow. They should be done first so that all new UI work uses the correct patterns.

#### 4.1a Define & Document UI Standards

- [x] **Button mapping** _(done 2026-03-02)_: 97 usages migrated. See `_bootstrap_enhancements.scss` for `btn-ghost` and touch-friendly sizing.
- [x] **Badge mapping** _(done 2026-03-02)_: All `badge bg-*` migrated to `badge text-bg-*` across 9 management views. Subtle variants use `bg-*-subtle text-*`. Domain mapping: active=`text-bg-success`, inactive=`text-bg-warning`, archived=`text-bg-danger`, info/metadata=`bg-primary-subtle text-primary` or `bg-secondary-subtle text-secondary`, lock/disabled=`text-bg-warning`, count=`text-bg-secondary`.
- [x] **Dropdown actions** _(done 2026-03-02)_: All row-level actions in items, sections, staff, and menus tables now use `shared/_actions_dropdown.html.erb` with 3-dot `bi-three-dots` trigger. Each dropdown includes Edit + contextual destructive action (Archive/Remove/Detach). Bulk actions remain as `<select>` dropdowns in table headers.
- [x] **Form controls** _(done 2026-03-02)_: 29 `form-control-2025`, 35 `form-label-2025`, 33 `form-group-2025`, 22 `form-help-2025` migrated to Bootstrap equivalents.
- [x] **Row-level status visualization** _(done 2026-03-02)_: `row-status-active` (green bg + green dot), `row-status-inactive` (gray bg + gray dot), `row-status-archived` (red bg + red dot). Opacity removed — background + CSS pseudo-element dot indicator only. Defined in `design_system_2025.scss`.
- [x] **Navigation rules** _(done 2026-03-02)_: Documented below in §4.1d.
- [x] **Confirmation UX** _(done 2026-03-02)_: Documented below in §4.1d.
- [x] **Empty states** _(done 2026-03-02)_: `EmptyStateComponent` used in items, sections, menus, staff, tables, allergens, sizes, localization, and versions. Each includes icon + title + description + optional CTA.

#### 4.1d Navigation & Confirmation Rules (documented 2026-03-02)

**Navigation patterns:**

| Context | Pattern | Example |
|---|---|---|
| Table row → edit page | `clickable-row` with `data-href` + `data-turbo-frame` | Menus, staff, tables, allergens, localization |
| Row action (single) | 3-dot `_actions_dropdown` partial | Items, sections, staff, menus |
| Row action → inline edit | `data-action="click->inline-edit#edit"` on cell | Item name/price in items table |
| Section → new page | `link_to` with `turbo_frame: '_top'` | Breadcrumb "Back to Items" |
| Sidebar → section swap | `turbo_frame: 'restaurant_content'` | Restaurant sidebar links |
| New tab | Never used in management views | — |

**Rules:**
- Clickable rows must not fire when clicking checkboxes, drag handles, or dropdowns (handled by `clickable_row_controller.js`).
- Primary row navigation is via `clickable-row`; the 3-dot dropdown provides Edit + destructive action.
- Inline edit (`inline_edit_controller.js`) takes precedence over clickable-row on editable cells.

**Confirmation patterns:**

| Context | Mechanism | Example |
|---|---|---|
| Single-item destructive action | `data-turbo-confirm` on link/button | Archive item, remove staff, detach menu |
| Bulk destructive action | Bootstrap modal via Stimulus controller | Bulk archive items/sections |
| Status toggle (reversible) | No confirmation needed | Activate/deactivate menu |
| Account-level destructive action | Bootstrap modal with explicit confirmation text | Delete restaurant (future) |

**Rule:** `turbo_confirm` is the default for row-level destructive actions. Bootstrap modals are used only when the action affects multiple items or requires extra input (e.g., selecting a status value for bulk update).

#### 4.1b CI Guardrails

- [x] CI check _(done 2026-03-02)_: `rake uiux:lint` flags any `-2025` class in views or JS. Wired into CI `quality` job.
- [ ] CI check: heuristic scan for hardcoded strings in views.

#### 4.1c Audit & Migration

- [x] **Full -2025 class purge** _(done 2026-03-02)_: Zero `-2025` CSS classes remain in views, JS, or SCSS. All custom component classes renamed (e.g. `sidebar-2025` → `sidebar-app`, `container-2025` → `container-app`). Legacy button/form SCSS renamed to `-legacy` suffix (dead code, safe to delete).
- [ ] Audit matrix: *Function* → *Screens* → *Current pattern* → *Target pattern* for badges, dropdowns, empty states, confirmations.
- [ ] Converge `restaurants/edit_2025` and all `restaurants/sections/_*_2025` to Bootstrap patterns.
- [ ] Converge `menus/edit_2025` and all `menus/sections/_*_2025` to Bootstrap patterns.
- [ ] Converge onboarding + auth flows to Bootstrap patterns.
- [ ] Converge customer SmartMenu flows to Bootstrap patterns.

### Priority 2: Kill Onboarding Wizard (from upgrade spec Phase 2)

> The wizard is dead code in practice — step 1 already redirects to restaurant edit. Removing it simplifies onboarding and eliminates dead code.

- [ ] Simplify `OnboardingController` to step 1 only (account details + restaurant name).
- [ ] After step 1: mark onboarding `completed`, redirect to `edit_restaurant_path` with `?onboarding=true`.
- [ ] Enhance go-live checklist (`_go_live_progress_2025.html.erb`) as canonical onboarding guide:
  - [ ] Auto-expand when `?onboarding=true` is present.
  - [ ] Each checklist item links directly to the relevant sidebar section.
  - [ ] Progress updates in real-time as user completes items.
- [ ] Add a brief welcome modal on first visit (dismissible, 3-second auto-dismiss).
- [ ] Delete dead wizard views: `show.html.erb`, `restaurant_details.html.erb`, `plan_selection.html.erb`, `menu_creation.html.erb`.
- [ ] Simplify `OnboardingSession` model (remove dead step enums).
- [ ] Delete `_onboarding.scss` inline styles.
- [ ] Add `data-testid` to all checklist items and account details form.
- [ ] System test: sign up -> account details -> restaurant edit with checklist visible.

### Priority 3: Smart Menu Customer — Remaining Layout & Performance

> These are the highest-ROI items for end users. The performance foundations are done; the major layout changes remain.

- [ ] Run Lighthouse audit on smartmenu pages; iterate until budget met (LCP <1.2s, INP <100ms, CLS <0.05, mobile score >=90).
- [ ] Limit initial render to first 3 sections; lazy-load remaining via IntersectionObserver.
- [ ] Add `Cache-Control: public, max-age=60, stale-while-revalidate=300` for smartmenu HTML.
- [ ] Verify fragment cache hit rates on menu items.
- [ ] Implement client-side search/filter debounce (150ms, filter via CSS class toggle, no DOM removal).
- [ ] Add search/filter for menu items by name (customer-facing, from action bar).

### Priority 4: Restaurant & Menu Management — Remaining Items

- [ ] Standardise all empty states using `EmptyStateComponent` across restaurant and menu sections.
- [ ] Create shared `_empty_state.html.erb` partial (ViewComponent exists but no partial wrapper).
- [ ] Unify the three AI poll functions (`pollProgress`, `pollPolishProgress`, `pollLocalizationProgress`) into a single generic `pollJobProgress()`.
- [ ] Make version diff accessible from a "History" badge on the menu header.
- [ ] Add `Cmd+S` / `Ctrl+S` keyboard shortcut for explicit form save.
- [ ] Add inline save indicator (replace flash messages for auto-save forms).
- [ ] Group sidebar sections behind expandable headers; default to collapsed for non-essential groups.
- [ ] Write system tests for: section switching, section reorder, inline edit.

### Priority 5: Smart Menu Staff View

> Staff view is functional but not differentiated from customer view.

- [ ] Add persistent staff banner at top: `"Staff View — [Table Name]"` with table switcher dropdown.
- [ ] Visual differentiation from customer view (coloured top border + background tint).
- [ ] Add quick-add quantity selector (long-press or stepper before adding to order).
- [ ] Add `data-testid` to all staff action buttons.
- [ ] Create `_staff_banner.html.erb` partial.
- [ ] Create `quick_add_controller.js` Stimulus controller.

### Priority 6: Dark Mode & Polish

- [ ] Implement dark mode: `prefers-color-scheme` media query + manual toggle (tokens already defined).
- [ ] Localise all remaining hardcoded user-facing strings via `t(...)`.
  - [ ] Prioritise 2025 surfaces first, then onboarding + smartmenu.
  - [ ] Define translation key structure (by feature/namespace).
- [ ] Final accessibility audit (axe-core scan). Target: zero WCAG 2.2 AA violations.
- [ ] Delete remaining orphaned wizard code, partials, and assets (post-wizard-kill cleanup).

### Priority 7: Audits & Documentation

> Ongoing / lower priority items from the overhaul spec.

- [ ] **Dead pages audit**: Compare core nav entry points (sidebars, dashboard, onboarding, staff dashboards) against `rails routes`. Decide per route: delete, hide behind admin, or re-link.
- [ ] **Non-localised content scan**: Backlog hardcoded strings with file/line references.
- [ ] **Navigation consistency audit**: Sidebars, back buttons, view vs edit destinations, Turbo frame usage.
- [ ] **Document the 7 canonical UI patterns** (Section Form, List/Table, Action Bar, Bottom Sheet, Progress/Status Card, Empty State, Inline Feedback) in a pattern library.
- [ ] **Open questions to resolve**:
  - [ ] Theme strategy: single brand theme, or per-restaurant theming?
  - [ ] Rollout approach: feature flags for visual changes, or direct refactors?

---

## 5. Definition of Done

- [ ] All 5 flows render correctly at 375px, 768px, and 1280px.
- [ ] Zero inline `<script>` or `<style>` blocks in view templates.
- [ ] Every interactive element has a `data-testid`.
- [ ] System tests exist for each flow's happy path.
- [ ] Lighthouse mobile score >=90 on smartmenu pages.
- [ ] All new user-facing strings are localised via `t(...)`.
- [ ] No accessibility violations (axe-core scan).
- [ ] The 7 canonical UI patterns are documented and used consistently.
- [ ] A developer can implement a new list screen without inventing new CSS.
- [ ] All "status" displays use the same badge component and same semantic colors.
- [ ] Zero `btn-2025` / `badge-2025` usage in 2025 surfaces (fully converged to Bootstrap).

---

## 6. Future Directions

- **Per-restaurant theming** — allow restaurants to customise smartmenu colours/fonts via admin UI.
- **Offline support** — Service Worker for smartmenu pages (browse menu without connectivity).
- **Native-feel transitions** — View Transitions API for page/section transitions (Chrome 111+).
- **Analytics dashboard redesign** — apply same mobile-first patterns to insights/analytics views.
- **Menu item detail modal** — tap list row to expand full description, allergens, and image gallery.
- **Voice ordering** — Web Speech API for hands-free menu navigation.

---

## Appendix A: Source Documents

- `docs/features/todo/2026/design/ui-ux-upgrade-spec.md` — Original flow-by-flow redesign spec (2026-02-13). Contains detailed design mockups, file lists, and performance budgets. Refer to it for wireframe diagrams and the 7 canonical pattern specifications.
- `docs/features/todo/2026/design/uiuxoverhaul.md` — Original CSS convergence plan. Contains detailed audit methodology. Refer to it for the Bootstrap migration checklists and CI guardrail specifications.
