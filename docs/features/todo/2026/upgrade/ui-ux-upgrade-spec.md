# UI/UX Upgrade — Design & Technical Specification

> **Status:** Draft
> **Author:** Cascade (AI pair-programmer) + FK
> **Date:** 2026-02-13
> **Companion doc:** `docs/features/todo/2026/design/uiuxoverhaul.md` (CSS convergence plan)

---

## 1. Executive Summary

This specification defines a **mobile-first, SaaS self-serve UI/UX upgrade** for mellow.menu, covering five user flows:

| Flow | Persona | Current layout |
|---|---|---|
| A. Onboarding | New restaurant owner | 5-step wizard (`OnboardingController`) |
| B. Restaurant management | Restaurant manager | Sidebar + Turbo frames (`edit_2025`) |
| C. Menu management | Restaurant manager | Sidebar + Turbo frames (`menus/edit_2025`) |
| D. Smart Menu (staff) | Logged-in staff | `smartmenu` layout, `showMenuContentStaff` |
| E. Smart Menu (customer) | Unauthenticated diner | `smartmenu` layout, `showMenuContentCustomer` |

### Design Principles (2026 SaaS Best Practice)

1. **Mobile-first** — every screen starts at 375px, then scales up.
2. **Progressive disclosure** — show only what's needed; advanced options behind expandable sections.
3. **Consistent interaction vocabulary** — same gesture/pattern for the same intent everywhere.
4. **Performance budget** — smartmenu pages: LCP <1.2s, INP <100ms, CLS <0.05.
5. **Testability by design** — every interactive element has `data-testid`, every view is system-testable.
6. **Accessibility** — WCAG 2.2 AA minimum; touch targets ≥44px; focus-visible on all interactables.

---

## 2. Current-State Audit & Findings

### 2.1 Onboarding Flow

**What exists:**
- 5-step wizard: Account Details → Restaurant Info → Plan Selection → Menu Creation → Completion.
- Left sidebar with progress bar + step indicators (desktop). Hardcoded `col-md-4` / `col-md-8` split.
- After step 1, the user is *redirected to the restaurant edit page* (`handle_account_details` → `redirect_to edit_restaurant_path`), bypassing steps 2-4.
- Inline `<style>` blocks in `show.html.erb` (~50 lines).

**Issues identified:**
- [ ] **Mobile breakage** — the `col-md-4` sidebar is full-width on mobile, pushing the form below the fold. No `d-none d-md-block` on the sidebar.
- [ ] **Flow abandonment** — step 1 redirects to the restaurant edit page, making the wizard steps 2-5 dead code in practice.
- [ ] **Inline styles** — ~50 lines of CSS baked into the wizard layout view.
- [ ] **No progress persistence on mobile** — the progress sidebar disappears on small screens; there's no compact mobile step indicator.
- [ ] **No skip/defer option** — plan selection and menu creation cannot be deferred.
- [ ] **Testimonial hardcoded** — "Set up our digital menu in under 5 minutes!" is not localised and not dynamic.
- [ ] **No `data-testid`** on most wizard elements (only `data-testid: 'restaurant-name'` on one field).

### 2.2 Restaurant Management Flow

**What exists:**
- 2025-style sidebar with 4 grouped sections (Restaurant / Menus / Operations / —).
- Content loaded via Turbo frames (`turbo_frame_tag 'restaurant_content'`).
- In-page onboarding checklist (go-live progress card) with expandable details.
- Sidebar controller (`data-controller="sidebar"`) for mobile toggle.
- Quick actions card on detail sections.

**Issues identified:**
- [ ] **Sidebar scroll on mobile** — full sidebar shown as overlay; no smooth scroll-to-active behavior.
- [ ] **Section count** — 15+ sidebar links; cognitive load is high for first-time users.
- [ ] **Inconsistent empty states** — some sections (e.g., allergens, sizes) show nothing when empty; others show an "add" prompt.
- [ ] **Inline page-specific `<style>` blocks** in `edit_2025.html.erb` (`.text-2xl`, `.text-gray-*`) that duplicate design system tokens.
- [ ] **No breadcrumb** on restaurant edit (unlike menu edit which has one).
- [ ] **Go-live checklist** is custom HTML; not reusable for other guided flows.
- [ ] **No keyboard shortcuts** for power users (e.g., `⌘+S` to save).
- [ ] **Auto-save is JS-only** — no Stimulus controller; bound via raw `addEventListener` in `edit_2025`.

### 2.3 Menu Management Flow

**What exists:**
- Same sidebar pattern as restaurant edit, with sections: Details / Sections / Items / Schedule / Settings / QR Code / Versions.
- AI progress modal (bottom-sheet on mobile) for image generation, localisation, and AI polish — ~420 lines of inline `<script>` in `edit_2025.html.erb`.
- Breadcrumb: Restaurant → Menus.
- `data-auto-save` forms.

**Issues identified:**
- [ ] **Massive inline script** — 420 lines of vanilla JS in the view file for AI modal, polling, progress. Not a Stimulus controller.
- [ ] **Three separate poll functions** (`pollProgress`, `pollPolishProgress`, `pollLocalizationProgress`) with nearly identical logic — code duplication.
- [ ] **No skeleton loading** for section content when switching sidebar tabs via Turbo.
- [ ] **Menu item editing** is multi-page (edit item → save → return to list). Inline editing would reduce friction.
- [ ] **Drag-to-reorder** for sections/items is not implemented in the 2025 views (only sequence numbers).
- [ ] **Version diff** view exists but is not prominently discoverable.

### 2.4 Smart Menu — Staff View

**What exists:**
- Same layout as customer view but with add-to-order buttons visible.
- Staff view determined by `current_user` presence.
- Sticky header with menu banner.
- Partial caching per smartmenu + menu + locale.

**Issues identified:**
- [ ] **Duplicate `class` attributes** in `_showMenuContentStaff.html.erb` (line 5: two `class=` attrs on the same div) — only the first is applied.
- [ ] **No quick-add quantity selector** — staff must tap "add", then adjust quantity in the order modal.
- [ ] **No table-switching affordance** — staff can't easily move to another table's context.
- [ ] **No visual differentiation** from customer view beyond the add buttons — staff often don't realise they're in the staff view.

### 2.5 Smart Menu — Customer View

**What exists:**
- Card-based menu items (`menu-item-card-mobile`).
- Welcome banner for first-time visitors (localStorage-based dismiss).
- Allergen filtering via `ordrparticipant.allergyns`.
- Fragment caching (30-min TTL for content, 1-hour for header).
- Skeleton loading partial exists but is not wired in.
- Scrollspy for section navigation.

**Issues identified:**
- [ ] **No search/filter** — customers can't search menu items by name.
- [ ] **Welcome banner uses inline `<script>`** — not a Stimulus controller; `onclick` handlers.
- [ ] **Skeleton loading partial exists but is unused** — `_skeleton_loading.html.erb` is never rendered.
- [ ] **Image loading** — `loading="lazy"` is set but no blur-up placeholder or LQIP.
- [ ] **Stripe JS loaded eagerly** on every smartmenu page (`<script src="https://js.stripe.com/v3">`) even when ordering is disabled — ~40kB unnecessary on browse-only pages.
- [ ] **No section sticky tabs** — scrollspy exists but no persistent section-tab bar for quick jumps.
- [ ] **Order review is modal-only** — no inline cart summary; users must open a modal to see their order.
- [ ] **No haptic/visual micro-feedback** on add-to-cart tap.
- [ ] **Footer renders on every smartmenu page** — unnecessary chrome for a mobile-first menu experience.

---

## 3. Clarifying Questions

Before finalising the implementation plan, I need your input on a few decisions:

### Design Direction
1. **Component library** — The existing `uiuxoverhaul.md` decided to converge on Bootstrap. Do you want to stay with **Bootstrap 5 + custom SCSS** for this upgrade, or move to a component system like **ViewComponent** (Rails) for better testability and encapsulation?

2. **Customer smartmenu look-and-feel** — Should the customer menu remain **card-based** (current), or would you prefer a **list-based** layout (like Deliveroo/Uber Eats) which is denser and faster to scan on mobile?

3. **Ordering model on customer view** — Currently the order is modal-based. Would you prefer a **persistent bottom sheet** (mini-cart always visible at the bottom, expandable) like modern food ordering apps?

### Scope & Priority
4. **Onboarding wizard** — Given step 1 already redirects to the restaurant edit page (making steps 2-5 dead code), should we:
   - **(a)** Fix the wizard to complete all 5 steps inline, OR
   - **(b)** Officially kill the wizard and make the restaurant edit page's go-live checklist the canonical onboarding?

5. **Inline menu item editing** — Is this a priority for this upgrade, or should we keep the current edit-on-separate-page pattern and focus on the customer-facing smartmenu performance?

6. **Dark mode** — The `_variables.scss` has commented-out dark mode variables. Is dark mode in scope for this upgrade?

### Technical
7. **Stimulus adoption** — The codebase has some Stimulus controllers (`sidebar`, `go-live-progress`, `disabled-action`) but the AI modal and auto-save are vanilla JS. Should this upgrade mandate **Stimulus for all new interactive behavior**?

8. **ViewComponent** — Would you like to adopt `ViewComponent` for reusable UI primitives (status badges, action menus, empty states), giving us unit-testable components?

9. **Performance budget enforcement** — Should we add **Lighthouse CI** to the GitHub Actions pipeline to gate smartmenu page performance?

---

## 4. Design Recommendations (2026 Best Practice)

### 4.1 Design System Alignment

**Recommendation:** Extend the existing `design_system_2025.scss` into a formal **Design Token + Component** system.

| Layer | Current | Proposed |
|---|---|---|
| **Tokens** | CSS custom properties in `design_system_2025.scss` | Keep; add motion + breakpoint tokens |
| **Components** | Mix of Bootstrap classes + `*_2025` classes + inline styles | Bootstrap 5 base + ViewComponent partials |
| **Patterns** | Ad-hoc per view | Documented pattern library (sidebar, form-section, list-row, empty-state, action-bar) |

#### New Tokens to Add

```scss
// Breakpoints (mobile-first)
--breakpoint-sm: 576px;
--breakpoint-md: 768px;
--breakpoint-lg: 1024px;
--breakpoint-xl: 1280px;

// Motion (reduced-motion aware)
--motion-duration-fast: 100ms;
--motion-duration-base: 200ms;
--motion-duration-slow: 350ms;
--motion-easing: cubic-bezier(0.25, 0.1, 0.25, 1);

// Touch targets
--touch-target-min: 44px;
--touch-target-comfortable: 48px;
```

### 4.2 Shared UI Patterns (the "comfortable slippers")

To deliver the consistent UX you described, define these **7 canonical patterns** that every flow must use:

#### Pattern 1: Section Form
Used in: Restaurant details, menu details, onboarding steps.

```
┌─────────────────────────────────┐
│ Section Title          [?] Help │
│ Subtitle / description          │
├─────────────────────────────────┤
│                                 │
│  Form fields (stacked mobile,  │
│  2-col on md+)                  │
│                                 │
├─────────────────────────────────┤
│              [Save] (auto-save  │
│              indicator if async)│
└─────────────────────────────────┘
```

- Auto-save with debounce (500ms) via Stimulus controller.
- Visual save indicator: subtle "Saved ✓" toast or inline text, not a full-page flash.
- On error: inline field-level errors, not top-of-page alerts.

#### Pattern 2: List / Table
Used in: Menu sections list, menu items, allergens, staff, tables.

```
┌─────────────────────────────────┐
│ List Title        [+ Add] [⋮]  │
│ Filter / Search (if >5 items)   │
├─────────────────────────────────┤
│ ☐ [drag] Item Name   Status [⋮]│
│ ☐ [drag] Item Name   Status [⋮]│
│ ☐ [drag] Item Name   Status [⋮]│
├─────────────────────────────────┤
│ [Bulk Actions] when selected    │
│ Showing 3 of 12 · Load more    │
└─────────────────────────────────┘
```

- Clickable rows navigate; `[⋮]` opens action dropdown.
- Drag handle for reordering (Sortable.js via Stimulus).
- Status shown as `badge` (Bootstrap semantic colors).
- Empty state: illustration + primary CTA.

#### Pattern 3: Action Bar (Smart Menu)
Used in: Customer and staff smartmenu views.

```
Mobile (sticky bottom):
┌─────────────────────────────────┐
│ [🔍 Search] [🍽 Sections] [🛒 3]│
└─────────────────────────────────┘
```

- Always visible, `position: fixed; bottom: 0`.
- Cart badge with item count, animated on add.
- Sections button opens a bottom sheet with section links.
- Search opens an overlay with instant client-side filter.

#### Pattern 4: Bottom Sheet
Used in: Cart/order review, section navigation, allergen filter, AI progress.

```
┌─────────────────────────────────┐
│ ─── (drag handle)               │
│ Title                    [✕]    │
├─────────────────────────────────┤
│                                 │
│  Content (scrollable)           │
│                                 │
├─────────────────────────────────┤
│ [Primary Action]                │
└─────────────────────────────────┘
```

- Replaces Bootstrap modals on mobile for cart, sections, filters.
- Swipe-down to dismiss.
- Three snap points: peek (25%), half (50%), full (90%).
- Implemented as a Stimulus controller wrapping a lightweight library.

#### Pattern 5: Progress / Status Card
Used in: Onboarding checklist, AI generation progress, go-live progress.

```
┌─────────────────────────────────┐
│ ✦ Setup Progress    3/9  [▸]   │
│ ████████░░░░░░░░░░   33%       │
│                                 │
│ (expandable: step list)         │
└─────────────────────────────────┘
```

- Reusable Stimulus controller `progress-card`.
- Accepts steps as JSON data attribute.
- Expand/collapse with animation.

#### Pattern 6: Empty State
Used in: Any list/section with zero items.

```
┌─────────────────────────────────┐
│        [illustration]           │
│                                 │
│     No items yet                │
│     Description of what to do   │
│                                 │
│     [+ Add First Item]          │
└─────────────────────────────────┘
```

- Consistent illustration style (line-art, brand-colored).
- Primary CTA always present.
- All text localised.

#### Pattern 7: Inline Feedback
Used in: Add-to-cart, form save, error states.

- **Success:** Subtle green check + "Saved" text that fades after 2s.
- **Add-to-cart:** Button briefly animates (scale + checkmark), cart badge bounces.
- **Error:** Field border turns red, inline error message appears below field.
- **Loading:** Skeleton shimmer (use existing `_skeleton_loading` partial).

---

## 5. Flow-by-Flow Redesign

### 5.1 Onboarding Flow

#### Design: Mobile-First Single-Page Wizard

Replace the current sidebar wizard with a **stepper-based single-column flow** that works identically on all screen sizes.

```
Mobile (375px):
┌─────────────────────────────────┐
│ ● ● ○ ○ ○  Step 2 of 5         │
│ ───────────── 40%               │
├─────────────────────────────────┤
│                                 │
│ Tell us about your restaurant   │
│                                 │
│ Restaurant Name ____________    │
│ Type          [▾ Select]        │
│ Cuisine       [▾ Select]        │
│ City/Location ____________      │
│                                 │
│ [← Back]           [Continue →] │
└─────────────────────────────────┘
```

**Key changes:**
- [ ] Remove the left sidebar layout; use a compact **horizontal stepper** (dots + progress bar) at the top.
- [ ] Fix step 1 to NOT redirect to restaurant edit. Complete the full wizard flow.
- [ ] Add "Skip for now" on optional steps (plan selection, menu creation).
- [ ] After completion, redirect to restaurant edit with the go-live checklist open.
- [ ] Extract inline styles to `_onboarding.scss`.
- [ ] Add `data-testid` to every field and button.
- [ ] Convert to Stimulus controller (`onboarding-wizard`) for step validation and transitions.
- [ ] Localise the testimonial or remove it.

#### Technical Implementation

```
New files:
- [ ] app/javascript/controllers/onboarding_wizard_controller.js
- [ ] app/views/shared/_stepper.html.erb (reusable horizontal stepper partial)

Modified files:
- [ ] app/views/onboarding/show.html.erb — replace sidebar layout with stepper
- [ ] app/views/onboarding/account_details.html.erb — add data-testid attrs
- [ ] app/views/onboarding/restaurant_details.html.erb — add data-testid attrs
- [ ] app/views/onboarding/plan_selection.html.erb — add "skip for now" link
- [ ] app/views/onboarding/menu_creation.html.erb — add "skip for now" link
- [ ] app/controllers/onboarding_controller.rb — fix handle_account_details to NOT redirect
- [ ] app/assets/stylesheets/pages/_onboarding.scss — absorb inline styles
```

#### Acceptance Criteria
- [ ] Wizard completes all 5 steps without leaving the onboarding flow.
- [ ] On mobile (375px), stepper + form are fully visible without horizontal scroll.
- [ ] Each step has `data-testid` on all interactive elements.
- [ ] System test: complete onboarding end-to-end (Capybara/Playwright).
- [ ] "Skip for now" on steps 3 and 4 advances to next step.

### 5.2 Restaurant Management Flow

#### Design: Contextual Sidebar with Smart Grouping

Keep the sidebar pattern (proven) but improve mobile experience and reduce cognitive load.

**Key changes:**
- [ ] Add a **breadcrumb** at the top: `Dashboard > [Restaurant Name]`.
- [ ] On mobile, replace overlay sidebar with a **horizontal scrollable tab bar** at the top (like iOS Settings / Shopify mobile).
- [ ] Group sidebar sections behind expandable headers; default to collapsed for non-essential groups.
- [ ] Add **skeleton loading** in the Turbo frame when switching sections.
- [ ] Add inline save indicator (replace flash messages for auto-save forms).
- [ ] Convert auto-save from raw JS to a `form-autosave` Stimulus controller.
- [ ] Standardize all empty states to use Pattern 6.
- [ ] Add `⌘+S` / `Ctrl+S` keyboard shortcut for explicit save.

#### Mobile Tab Bar

```
┌─────────────────────────────────────────────────┐
│ [Details] [Hours] [Langs] [Menus] [Staff] [...] │  ← scrollable
└─────────────────────────────────────────────────┘
```

- `d-md-none` — visible only on mobile.
- Active tab has bottom border + bold text.
- Overflow indicator (fade gradient on right edge).

#### Technical Implementation

```
New files:
- [ ] app/javascript/controllers/form_autosave_controller.js
- [ ] app/javascript/controllers/tab_bar_controller.js
- [ ] app/views/shared/_mobile_tab_bar.html.erb
- [ ] app/views/shared/_skeleton_frame.html.erb (Turbo frame skeleton)
- [ ] app/views/shared/_empty_state.html.erb (Pattern 6)
- [ ] app/views/shared/_inline_save_indicator.html.erb

Modified files:
- [ ] app/views/restaurants/edit_2025.html.erb — add breadcrumb, mobile tab bar, remove inline styles
- [ ] app/views/restaurants/_sidebar_2025.html.erb — add expandable groups, `d-none d-md-block`
- [ ] app/views/restaurants/sections/_details_2025.html.erb — use empty state partial
- [ ] app/views/restaurants/sections/_allergens_2025.html.erb — use empty state partial
- [ ] app/assets/stylesheets/components/_sidebar_2025.scss — add mobile tab bar styles
```

#### Acceptance Criteria
- [ ] On mobile (<768px), the sidebar is replaced by a scrollable tab bar.
- [ ] Switching sections shows a skeleton loader before Turbo content loads.
- [ ] Auto-save shows "Saved ✓" inline (not flash banner).
- [ ] All empty sections show a consistent empty state with a primary CTA.
- [ ] `⌘+S` triggers form save on macOS; `Ctrl+S` on Windows/Linux.

### 5.3 Menu Management Flow

#### Design: Streamlined Menu Builder

**Key changes:**
- [ ] Extract the AI modal JS (~420 lines) into a **Stimulus controller** (`ai-progress`).
- [ ] Unify the three poll functions into a single generic `pollJobProgress()`.
- [ ] Add **Turbo frame skeleton** when switching sidebar sections.
- [ ] Add drag-to-reorder for menu sections and items (Sortable.js + Stimulus).
- [ ] Add inline "quick edit" for item name/price (click to edit, blur to save).
- [ ] Make version diff accessible from a "History" badge on the menu header.

#### Technical Implementation

```
New files:
- [ ] app/javascript/controllers/ai_progress_controller.js (~150 lines, replaces 420 inline)
- [ ] app/javascript/controllers/sortable_controller.js (drag-to-reorder)
- [ ] app/javascript/controllers/inline_edit_controller.js (click-to-edit fields)

Modified files:
- [ ] app/views/menus/edit_2025.html.erb — remove inline <script>, wire Stimulus controllers
- [ ] app/views/menus/sections/_sections_2025.html.erb — add sortable + inline edit
- [ ] app/views/menus/sections/_items_2025.html.erb — add sortable + inline edit
```

#### Acceptance Criteria
- [ ] Zero inline `<script>` blocks in `menus/edit_2025.html.erb`.
- [ ] AI image generation, localisation, and polish all use the same Stimulus controller.
- [ ] Menu sections can be reordered via drag-and-drop; new order persists via PATCH.
- [ ] System test: reorder sections and verify new sequence saved.

### 5.4 Smart Menu — Staff View

#### Design: Staff-Differentiated Experience

**Key changes:**
- [ ] Add a persistent **staff banner** at the top: `"Staff View — [Table Name]"` with a table switcher dropdown.
- [ ] Different background colour or top-border to visually distinguish from customer view.
- [ ] Add **quick-add with quantity** — long-press or swipe on item to set quantity before adding.
- [ ] Fix the duplicate `class` attribute in `_showMenuContentStaff.html.erb`.
- [ ] Add `data-testid` to all action buttons.

#### Technical Implementation

```
New files:
- [ ] app/views/shared/_staff_banner.html.erb
- [ ] app/javascript/controllers/quick_add_controller.js

Modified files:
- [ ] app/views/smartmenus/_showMenuContentStaff.html.erb — fix duplicate class attr
- [ ] app/views/smartmenus/show.html.erb — render staff banner when in staff mode
- [ ] app/views/layouts/smartmenu.html.erb — conditional staff styling
```

#### Acceptance Criteria
- [ ] Staff banner visible at top of staff view; not visible in customer view.
- [ ] Table switcher dropdown allows moving to another table's smartmenu.
- [ ] Quick-add with quantity works on touch and desktop.
- [ ] No duplicate `class` attributes in any smartmenu partial.

### 5.5 Smart Menu — Customer View (Performance Focus)

#### Design: Ultra-Fast Mobile Menu Experience

This is the highest-impact flow. Every millisecond counts.

**Key changes:**
- [ ] Add a **sticky action bar** at the bottom (Pattern 3) with Search, Sections, and Cart.
- [ ] Implement **client-side search/filter** — instant filter menu items as user types (no server round-trip).
- [ ] Replace Bootstrap modals with **bottom sheets** (Pattern 4) for cart and section navigation.
- [ ] Wire the **skeleton loading** partial (`_skeleton_loading.html.erb`) as a placeholder while content loads.
- [ ] Add **LQIP (Low Quality Image Placeholder)** for menu item images — 20px wide blurred placeholder inline as base64.
- [ ] **Lazy-load Stripe JS** — only load `stripe.js` when the user opens the payment flow, not on page load.
- [ ] Remove the footer from the smartmenu layout for customers (saves DOM + paint).
- [ ] Add **section sticky tabs** — horizontal scrollable section names that stick below the header.
- [ ] Add **micro-animations** on add-to-cart: button animates, cart badge bounces.
- [ ] Convert welcome banner from inline `<script>` to Stimulus controller.

#### Performance Budget

| Metric | Current (est.) | Target |
|---|---|---|
| LCP | ~2.5s | <1.2s |
| INP | ~200ms | <100ms |
| CLS | ~0.15 | <0.05 |
| JS payload (smartmenu) | ~180kB | <100kB |
| First meaningful paint | ~1.8s | <1.0s |

#### Performance Implementation

```
1. Defer Stripe JS:
   - [ ] Remove <script src="stripe.js"> from smartmenu layout
   - [ ] Load it dynamically when user opens payment/checkout flow

2. Image optimisation:
   - [ ] Generate LQIP (20px thumbnails) at upload time via ActiveStorage variant
   - [ ] Render LQIP as base64 data-uri in <img> placeholder
   - [ ] Add CSS blur transition: .lqip { filter: blur(10px); transition: filter 0.3s; }

3. Reduce DOM:
   - [ ] Remove footer from customer smartmenu view
   - [ ] Remove unused debug blocks from production HTML
   - [ ] Limit initial render to first 3 sections; lazy-load remaining via IntersectionObserver

4. Cache optimisation:
   - [ ] Add Cache-Control: public, max-age=60, stale-while-revalidate=300 for smartmenu HTML
   - [ ] Fragment cache individual menu items (already done, but verify hit rates)

5. Client-side search:
   - [ ] Build search index from data-name/data-description attrs already on menu items
   - [ ] Stimulus controller: filter items on input; show/hide via CSS class toggle (no DOM removal)
   - [ ] Debounce 150ms
```

#### Technical Implementation

```
New files:
- [ ] app/javascript/controllers/menu_search_controller.js
- [ ] app/javascript/controllers/bottom_sheet_controller.js
- [ ] app/javascript/controllers/section_tabs_controller.js
- [ ] app/javascript/controllers/cart_badge_controller.js
- [ ] app/javascript/controllers/welcome_banner_controller.js
- [ ] app/javascript/controllers/lazy_stripe_controller.js
- [ ] app/views/smartmenus/_sticky_action_bar.html.erb
- [ ] app/views/smartmenus/_section_tabs.html.erb
- [ ] app/views/shared/_bottom_sheet.html.erb

Modified files:
- [ ] app/views/layouts/smartmenu.html.erb — remove eager Stripe, conditional footer
- [ ] app/views/smartmenus/show.html.erb — wire skeleton, section tabs, action bar
- [ ] app/views/smartmenus/_showMenuitemHorizontal.html.erb — add LQIP placeholders
- [ ] app/views/smartmenus/_welcome_banner.html.erb — convert to Stimulus
- [ ] app/controllers/smartmenus_controller.rb — add Cache-Control headers
- [ ] app/assets/stylesheets/pages/_smartmenu.scss — action bar, section tabs, LQIP styles
```

#### Acceptance Criteria
- [ ] Lighthouse mobile score ≥90 on a smartmenu page with 20+ items.
- [ ] LCP <1.2s on 4G throttle (Lighthouse simulated).
- [ ] Client-side search filters items in <50ms for a 100-item menu.
- [ ] Stripe JS is not loaded until checkout is initiated.
- [ ] No layout shift when images load (CLS <0.05).
- [ ] Cart badge animates on item add.
- [ ] Section tabs stick below header on scroll.

---

## 6. Testability Strategy

### 6.1 Data-Testid Convention

Every interactive element must have a `data-testid` attribute following this convention:

```
data-testid="[context]-[element]-[identifier]"

Examples:
  data-testid="onboarding-continue-btn"
  data-testid="restaurant-sidebar-menus-link"
  data-testid="smartmenu-add-item-42"
  data-testid="cart-badge-count"
  data-testid="search-input"
  data-testid="section-tab-starters"
```

### 6.2 System Test Coverage

| Flow | Test type | Tool | Priority |
|---|---|---|---|
| Onboarding complete | System test | Capybara + Selenium | High |
| Restaurant section switching | System test | Capybara | Medium |
| Menu section reorder | System test | Capybara + drag simulation | Medium |
| Smartmenu add-to-cart | System test | Capybara | High |
| Smartmenu search/filter | System test | Capybara | High |
| Smartmenu performance | Lighthouse CI | `@lhci/cli` | High |

### 6.3 Component Tests (ViewComponent)

If ViewComponent is adopted, each UI primitive gets a unit test:

```ruby
# test/components/status_badge_component_test.rb
class StatusBadgeComponentTest < ViewComponent::TestCase
  def test_renders_active_badge
    render_inline(StatusBadgeComponent.new(status: :active))
    assert_selector "span.badge.text-bg-success", text: "Active"
  end

  def test_renders_inactive_badge
    render_inline(StatusBadgeComponent.new(status: :inactive))
    assert_selector "span.badge.text-bg-secondary", text: "Inactive"
  end
end
```

### 6.4 Lighthouse CI Integration

```yaml
# .github/workflows/ci.yml — new job
lighthouse:
  runs-on: ubuntu-latest
  needs: [test]
  steps:
    - uses: actions/checkout@v4
    - uses: treosh/lighthouse-ci-action@v12
      with:
        urls: |
          http://localhost:3000/smartmenus/test-slug
        budgetPath: ./lighthouse-budget.json
        uploadArtifacts: true
```

```json
// lighthouse-budget.json
[{
  "path": "/smartmenus/*",
  "timings": [
    { "metric": "largest-contentful-paint", "budget": 1200 },
    { "metric": "interactive", "budget": 2000 }
  ],
  "resourceSizes": [
    { "resourceType": "script", "budget": 100 },
    { "resourceType": "total", "budget": 500 }
  ]
}]
```

---

## 7. Implementation Roadmap

### Phase 1 — Foundation (1 week)
- [ ] Create shared UI partials: `_stepper`, `_empty_state`, `_bottom_sheet`, `_mobile_tab_bar`, `_inline_save_indicator`
- [ ] Create Stimulus controllers: `form-autosave`, `bottom-sheet`, `tab-bar`
- [ ] Add design tokens to `design_system_2025.scss` (motion, breakpoints, touch targets)
- [ ] Add `data-testid` to all existing interactive elements across 5 flows
- [ ] Set up Lighthouse CI job in GitHub Actions

### Phase 2 — Onboarding (3-4 days)
- [ ] Rebuild wizard as single-column stepper flow
- [ ] Fix `handle_account_details` to not redirect out of wizard
- [ ] Add "Skip for now" to optional steps
- [ ] Extract inline styles
- [ ] Write system test: complete onboarding end-to-end

### Phase 3 — Restaurant & Menu Management (1-2 weeks)
- [ ] Add mobile tab bar to restaurant edit
- [ ] Add Turbo frame skeleton loading
- [ ] Extract AI modal JS to Stimulus controller
- [ ] Add drag-to-reorder for sections and items
- [ ] Standardise all empty states
- [ ] Write system tests for section switching and reorder

### Phase 4 — Smart Menu Customer (1-2 weeks) ← **Highest ROI**
- [ ] Implement sticky action bar (search, sections, cart)
- [ ] Build client-side menu search
- [ ] Replace modals with bottom sheets
- [ ] Add section sticky tabs
- [ ] Defer Stripe JS loading
- [ ] Add LQIP for images
- [ ] Remove footer for customers
- [ ] Add micro-animations (cart badge, add button)
- [ ] Wire skeleton loading partial
- [ ] Run Lighthouse audit; iterate until budget met

### Phase 5 — Smart Menu Staff (3-4 days)
- [ ] Add staff banner with table switcher
- [ ] Add quick-add quantity selector
- [ ] Fix duplicate class attributes
- [ ] Visual differentiation (border/background)

### Phase 6 — Polish & Cleanup (ongoing)
- [ ] Remove all inline `<script>` and `<style>` blocks from views
- [ ] Localise all remaining hardcoded strings
- [ ] Remove dead onboarding code (if wizard approach confirmed)
- [ ] Delete orphaned partials/assets

---

## 8. New Files Summary

| File | Phase | Type |
|---|---|---|
| `app/javascript/controllers/onboarding_wizard_controller.js` | 2 | Stimulus |
| `app/javascript/controllers/form_autosave_controller.js` | 1 | Stimulus |
| `app/javascript/controllers/tab_bar_controller.js` | 1 | Stimulus |
| `app/javascript/controllers/ai_progress_controller.js` | 3 | Stimulus |
| `app/javascript/controllers/sortable_controller.js` | 3 | Stimulus |
| `app/javascript/controllers/inline_edit_controller.js` | 3 | Stimulus |
| `app/javascript/controllers/menu_search_controller.js` | 4 | Stimulus |
| `app/javascript/controllers/bottom_sheet_controller.js` | 1 | Stimulus |
| `app/javascript/controllers/section_tabs_controller.js` | 4 | Stimulus |
| `app/javascript/controllers/cart_badge_controller.js` | 4 | Stimulus |
| `app/javascript/controllers/welcome_banner_controller.js` | 4 | Stimulus |
| `app/javascript/controllers/lazy_stripe_controller.js` | 4 | Stimulus |
| `app/views/shared/_stepper.html.erb` | 1 | Partial |
| `app/views/shared/_empty_state.html.erb` | 1 | Partial |
| `app/views/shared/_bottom_sheet.html.erb` | 1 | Partial |
| `app/views/shared/_mobile_tab_bar.html.erb` | 1 | Partial |
| `app/views/shared/_skeleton_frame.html.erb` | 1 | Partial |
| `app/views/shared/_inline_save_indicator.html.erb` | 1 | Partial |
| `app/views/shared/_staff_banner.html.erb` | 5 | Partial |
| `app/views/smartmenus/_sticky_action_bar.html.erb` | 4 | Partial |
| `app/views/smartmenus/_section_tabs.html.erb` | 4 | Partial |
| `lighthouse-budget.json` | 1 | Config |

---

## 9. Modified Files Summary

| File | Phase | Changes |
|---|---|---|
| `app/views/onboarding/show.html.erb` | 2 | Replace sidebar layout with stepper |
| `app/views/onboarding/account_details.html.erb` | 2 | Add data-testid attrs |
| `app/views/onboarding/restaurant_details.html.erb` | 2 | Add data-testid attrs |
| `app/views/onboarding/plan_selection.html.erb` | 2 | Add skip, data-testid |
| `app/views/onboarding/menu_creation.html.erb` | 2 | Add skip, data-testid |
| `app/controllers/onboarding_controller.rb` | 2 | Fix step 1 redirect |
| `app/assets/stylesheets/pages/_onboarding.scss` | 2 | Absorb inline styles |
| `app/views/restaurants/edit_2025.html.erb` | 3 | Breadcrumb, tab bar, remove inline styles |
| `app/views/restaurants/_sidebar_2025.html.erb` | 3 | Expandable groups, mobile hide |
| `app/views/menus/edit_2025.html.erb` | 3 | Remove inline script, wire Stimulus |
| `app/views/menus/sections/_sections_2025.html.erb` | 3 | Sortable + inline edit |
| `app/views/menus/sections/_items_2025.html.erb` | 3 | Sortable + inline edit |
| `app/views/layouts/smartmenu.html.erb` | 4 | Defer Stripe, conditional footer |
| `app/views/smartmenus/show.html.erb` | 4 | Section tabs, action bar, skeleton |
| `app/views/smartmenus/_showMenuitemHorizontal.html.erb` | 4 | LQIP placeholders |
| `app/views/smartmenus/_showMenuContentStaff.html.erb` | 5 | Fix duplicate class attr |
| `app/views/smartmenus/_welcome_banner.html.erb` | 4 | Convert to Stimulus |
| `app/controllers/smartmenus_controller.rb` | 4 | Cache-Control headers |
| `app/assets/stylesheets/design_system_2025.scss` | 1 | New tokens |
| `app/assets/stylesheets/pages/_smartmenu.scss` | 4 | Action bar, tabs, LQIP |
| `.github/workflows/ci.yml` | 1 | Lighthouse CI job |

---

## 10. Definition of Done

- [ ] All 5 flows render correctly at 375px, 768px, and 1280px.
- [ ] Zero inline `<script>` or `<style>` blocks in view templates.
- [ ] Every interactive element has a `data-testid`.
- [ ] System tests exist for each flow's happy path.
- [ ] Lighthouse mobile score ≥90 on smartmenu pages.
- [ ] All new user-facing strings are localised via `t(...)`.
- [ ] No accessibility violations (axe-core scan).
- [ ] The 7 canonical UI patterns are documented and used consistently.

---

## 11. Future Directions

- **Per-restaurant theming** — allow restaurants to customise smartmenu colours/fonts via admin UI.
- **Dark mode** — toggle based on system preference; tokens already partially defined.
- **Offline support** — Service Worker for smartmenu pages (browse menu without connectivity).
- **Native-feel transitions** — View Transitions API for page/section transitions (Chrome 111+).
- **Analytics dashboard redesign** — apply same mobile-first patterns to insights/analytics views.
