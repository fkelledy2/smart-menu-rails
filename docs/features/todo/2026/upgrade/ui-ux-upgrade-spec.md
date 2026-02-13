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

## 3. Design Decisions (Confirmed 2026-02-13)

| # | Question | Decision |
|---|---|---|
| 1 | Onboarding approach | **Kill the wizard.** Use the restaurant edit go-live checklist as canonical onboarding. |
| 2 | Customer smartmenu layout | **List-based** (Deliveroo/Uber Eats style) — denser, faster to scan on mobile. |
| 3 | Cart/order UX | **Persistent bottom sheet** (mini-cart always visible, expandable). Replace modal-based order review. |
| 4 | Stimulus mandate | **Yes.** All new interactive JS must be Stimulus controllers. |
| 5 | ViewComponent | **Yes.** Adopt ViewComponent for reusable UI primitives (status badges, action menus, empty states). |
| 6 | Inline menu item editing | **Yes, in scope.** Implement click-to-edit for item name/price in the menu management view. |
| 7 | Dark mode | **Yes, in scope.** Implement as Phase 6 using `prefers-color-scheme` + manual toggle. |
| 8 | Lighthouse CI | **Yes.** Add to GitHub Actions pipeline to gate smartmenu page performance. |
| 9 | CSS framework | **Bootstrap 5 + custom SCSS.** No framework change; extend the existing design system. |

### Implications of These Decisions

- **Onboarding wizard (steps 2-5) becomes dead code** — will be removed in Phase 2. Step 1 (account details) remains as initial account setup, then redirects to restaurant edit with go-live checklist.
- **ViewComponent gem** must be added to `Gemfile`.
- **Customer smartmenu** will undergo a significant layout change from cards to list rows — this is the largest visual change.
- **Dark mode** is deferred to Phase 6 but tokens should be defined in Phase 1 for forward compatibility.

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

### 5.1 Onboarding Flow — Kill Wizard, Enhance Go-Live Checklist

> **Decision:** The 5-step onboarding wizard is dead code (step 1 already redirects to restaurant edit). Kill it. The restaurant edit page's **go-live checklist** becomes the canonical onboarding experience.

#### Design: Streamlined Account Setup → Go-Live Checklist

```
Step 1 (unchanged): Account Details (lightweight form)
  ┌─────────────────────────────────┐
  │ Welcome to mellow.menu!         │
  │                                 │
  │ Your Name _______________       │
  │ Restaurant Name _________       │
  │                                 │
  │ [Get Started →]                 │
  └─────────────────────────────────┘
          │
          ▼
Step 2: Redirect → Restaurant Edit with Go-Live checklist expanded
  ┌─────────────────────────────────┐
  │ ✦ Go Live Checklist    2/9 [▸] │
  │ ████░░░░░░░░░░░░░░░░   22%     │
  │                                 │
  │ ✓ Create account                │
  │ ✓ Name your restaurant          │
  │ → Add restaurant details        │  ← highlighted next step
  │ ○ Set opening hours             │
  │ ○ Create your first menu        │
  │ ○ Add menu sections             │
  │ ○ Add menu items                │
  │ ○ Choose a plan                 │
  │ ○ Activate restaurant           │
  └─────────────────────────────────┘
```

**Key changes:**
- [ ] Simplify `OnboardingController` to only handle step 1 (account details + restaurant name).
- [ ] After step 1, mark onboarding as `completed` and redirect to `edit_restaurant_path` with `?onboarding=true` param.
- [ ] Enhance the existing go-live checklist (`_go_live_progress_2025.html.erb`) to be the full onboarding guide.
- [ ] Go-live checklist auto-expands when `?onboarding=true` is present.
- [ ] Each checklist item links directly to the relevant sidebar section.
- [ ] Add a **welcome modal** on first visit (brief, dismissible, 3-second auto-dismiss).
- [ ] Remove dead wizard views: `restaurant_details.html.erb`, `plan_selection.html.erb`, `menu_creation.html.erb`, `show.html.erb` (wizard layout).
- [ ] Remove dead wizard steps from `OnboardingSession` model.
- [ ] Add `data-testid` to all checklist items and account details form.

#### Technical Implementation

```
Remove (dead code):
- [ ] app/views/onboarding/show.html.erb (wizard layout)
- [ ] app/views/onboarding/restaurant_details.html.erb
- [ ] app/views/onboarding/plan_selection.html.erb
- [ ] app/views/onboarding/menu_creation.html.erb
- [ ] app/assets/stylesheets/pages/_onboarding.scss (inline styles for wizard)

Modified files:
- [ ] app/controllers/onboarding_controller.rb — simplify to step 1 only, redirect to restaurant edit
- [ ] app/models/onboarding_session.rb — simplify status enum (remove dead steps)
- [ ] app/views/onboarding/account_details.html.erb — add data-testid, mobile-first layout
- [ ] app/views/restaurants/sections/_go_live_progress_2025.html.erb — enhance as canonical onboarding
- [ ] app/views/restaurants/edit_2025.html.erb — auto-expand checklist when ?onboarding=true
- [ ] app/javascript/controllers/go_live_progress_controller.js — enhance with onboarding mode
```

#### Acceptance Criteria
- [ ] New user signs up → account details form → restaurant edit page with go-live checklist expanded.
- [ ] No wizard steps 2-5 are reachable via any URL.
- [ ] Go-live checklist items link to correct sidebar sections.
- [ ] System test: sign up → complete account details → land on restaurant edit with checklist visible.
- [ ] Checklist progress updates in real-time as user completes items.

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

#### Design: List-Based Mobile Menu with Persistent Cart

> **Decision:** Switch from card-based to **list-based layout** (Deliveroo/Uber Eats style). Replace modal cart with **persistent bottom sheet**.

This is the highest-impact flow. Every millisecond counts.

```
Mobile (375px):
┌─────────────────────────────────┐
│ [Restaurant Logo]  🌐 EN  🔍   │  ← sticky header
├─────────────────────────────────┤
│ [Starters] [Mains] [Desserts]  │  ← sticky section tabs (scrollable)
├─────────────────────────────────┤
│                                 │
│ STARTERS                        │
│ ┌─────────────────────────────┐ │
│ │ [img] Bruschetta        €8  │ │  ← list row: thumbnail + name + price
│ │       Tomato, basil, gar…   │ │     description truncated to 1 line
│ │       🥜 🌾          [+ Add]│ │     allergen icons + add button
│ ├─────────────────────────────┤ │
│ │ [img] Caprese Salad    €10  │ │
│ │       Fresh mozzarella…     │ │
│ │                      [+ Add]│ │
│ ├─────────────────────────────┤ │
│ │ [img] Arancini          €7  │ │
│ │       Fried risotto bal…    │ │
│ │       🧀             [+ Add]│ │
│ └─────────────────────────────┘ │
│                                 │
│ MAINS                           │
│ ...                             │
│                                 │
├─────────────────────────────────┤  ← persistent bottom sheet (peek)
│ ─── Cart · 3 items · €25.00    │
│ [View Order →]                  │
└─────────────────────────────────┘

Bottom sheet expanded (half):
┌─────────────────────────────────┐
│ ─── Your Order          [✕]    │
├─────────────────────────────────┤
│ Bruschetta          1 ×  €8.00 │
│ [−] [1] [+]                    │
│ Caprese Salad       1 × €10.00 │
│ [−] [1] [+]                    │
│ Arancini            1 ×  €7.00 │
│ [−] [1] [+]                    │
├─────────────────────────────────┤
│ Subtotal                €25.00 │
│ [Place Order — €25.00]          │
└─────────────────────────────────┘
```

**Key changes:**
- [ ] **Replace card layout** with list rows: 60px thumbnail (left) + name/desc/price (right) + add button.
- [ ] Add a **sticky action bar / persistent bottom sheet** (peek state) showing cart summary + item count.
- [ ] Bottom sheet expands to half/full for order review with quantity controls.
- [ ] Implement **client-side search/filter** — instant filter menu items as user types (no server round-trip).
- [ ] Wire the **skeleton loading** partial (`_skeleton_loading.html.erb`) as a placeholder while content loads.
- [ ] Add **LQIP (Low Quality Image Placeholder)** for menu item images — 20px wide blurred placeholder inline as base64.
- [ ] **Lazy-load Stripe JS** — only load `stripe.js` when the user opens the payment flow, not on page load.
- [ ] Remove the footer from the smartmenu layout for customers (saves DOM + paint).
- [ ] Add **section sticky tabs** — horizontal scrollable section names that stick below the header.
- [ ] Add **micro-animations** on add-to-cart: button animates, cart badge bounces.
- [ ] Convert welcome banner from inline `<script>` to Stimulus controller.

#### List Row Specification

```
┌────┬──────────────────────────────┐
│    │ Item Name              €12.50│  ← font-semibold, var(--text-base)
│ img│ Short description text…      │  ← text-gray-500, var(--text-sm), max 1 line, ellipsis
│60px│ 🥜 🌾                [+ Add] │  ← allergen icons (14px) + 44px touch target button
└────┴──────────────────────────────┘
Height: 80px (no image) / 88px (with image)
Separator: 1px var(--color-gray-100) bottom border
Thumbnail: 60×60px, rounded-md, object-fit: cover
```

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

ViewComponent is adopted for all reusable UI primitives. Each gets a unit test:

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
- [ ] Add `view_component` gem to Gemfile; run `bundle install`
- [ ] Create ViewComponents: `StatusBadgeComponent`, `EmptyStateComponent`, `ActionMenuComponent`
- [ ] Create shared partials: `_empty_state`, `_bottom_sheet`, `_mobile_tab_bar`, `_inline_save_indicator`, `_skeleton_frame`
- [ ] Create Stimulus controllers: `form-autosave`, `bottom-sheet`, `tab-bar`
- [ ] Add design tokens to `design_system_2025.scss` (motion, breakpoints, touch targets, dark mode tokens)
- [ ] Add `data-testid` to all existing interactive elements across all flows
- [ ] Set up Lighthouse CI job in GitHub Actions + `lighthouse-budget.json`
- [ ] Write ViewComponent unit tests

### Phase 2 — Kill Wizard, Enhance Go-Live Checklist (3-4 days)
- [ ] Simplify `OnboardingController` to step 1 only (account details + restaurant name)
- [ ] After step 1: mark onboarding complete, redirect to restaurant edit with `?onboarding=true`
- [ ] Enhance go-live checklist as canonical onboarding (auto-expand, linked steps)
- [ ] Delete dead wizard views: `show.html.erb`, `restaurant_details.html.erb`, `plan_selection.html.erb`, `menu_creation.html.erb`
- [ ] Simplify `OnboardingSession` model (remove dead step enums)
- [ ] Delete `_onboarding.scss` inline styles
- [ ] Write system test: sign up → account details → restaurant edit with checklist

### Phase 3 — Restaurant & Menu Management (1-2 weeks)
- [ ] Add mobile tab bar to restaurant edit (`d-md-none` scrollable tabs)
- [ ] Add Turbo frame skeleton loading
- [ ] Extract AI modal JS (~420 lines) to `ai-progress` Stimulus controller
- [ ] Add drag-to-reorder for menu sections and items (Sortable.js + Stimulus)
- [ ] Add inline click-to-edit for menu item name/price
- [ ] Standardise all empty states using `EmptyStateComponent`
- [ ] Add breadcrumb to restaurant edit
- [ ] Convert auto-save to `form-autosave` Stimulus controller
- [ ] Write system tests for section switching, reorder, and inline edit

### Phase 4 — Smart Menu Customer (1-2 weeks) ← **Highest ROI**
- [ ] Replace card layout with list-based rows (Deliveroo/Uber Eats style)
- [ ] Implement persistent bottom sheet cart (peek/half/full snap points)
- [ ] Build client-side menu search (Stimulus, filter via data attrs)
- [ ] Add section sticky tabs (scrollable, highlight on scroll)
- [ ] Defer Stripe JS loading (lazy-load on checkout)
- [ ] Add LQIP for menu item images (base64 blur-up)
- [ ] Remove footer for customer smartmenu
- [ ] Add micro-animations (cart badge bounce, add button scale)
- [ ] Wire skeleton loading partial
- [ ] Convert welcome banner to Stimulus controller
- [ ] Run Lighthouse audit; iterate until budget met (LCP <1.2s, INP <100ms)

### Phase 5 — Smart Menu Staff (3-4 days)
- [ ] Add staff banner with table switcher dropdown
- [ ] Add quick-add quantity selector (long-press / stepper)
- [ ] Fix duplicate `class` attributes in `_showMenuContentStaff.html.erb`
- [ ] Visual differentiation (coloured top border + background tint)

### Phase 6 — Dark Mode & Polish (1 week)
- [ ] Implement dark mode: `prefers-color-scheme` + manual toggle
- [ ] Define dark mode token overrides in `:root[data-theme="dark"]`
- [ ] Remove all inline `<script>` and `<style>` blocks from views
- [ ] Localise all remaining hardcoded strings
- [ ] Delete orphaned wizard code, partials, and assets
- [ ] Final accessibility audit (axe-core scan)

---

## 8. New Files Summary

| File | Phase | Type |
|---|---|---|
| `app/components/status_badge_component.rb` | 1 | ViewComponent |
| `app/components/status_badge_component.html.erb` | 1 | ViewComponent |
| `app/components/empty_state_component.rb` | 1 | ViewComponent |
| `app/components/empty_state_component.html.erb` | 1 | ViewComponent |
| `app/components/action_menu_component.rb` | 1 | ViewComponent |
| `app/components/action_menu_component.html.erb` | 1 | ViewComponent |
| `test/components/status_badge_component_test.rb` | 1 | Test |
| `test/components/empty_state_component_test.rb` | 1 | Test |
| `test/components/action_menu_component_test.rb` | 1 | Test |
| `app/javascript/controllers/form_autosave_controller.js` | 1 | Stimulus |
| `app/javascript/controllers/tab_bar_controller.js` | 1 | Stimulus |
| `app/javascript/controllers/bottom_sheet_controller.js` | 1 | Stimulus |
| `app/javascript/controllers/ai_progress_controller.js` | 3 | Stimulus |
| `app/javascript/controllers/sortable_controller.js` | 3 | Stimulus |
| `app/javascript/controllers/inline_edit_controller.js` | 3 | Stimulus |
| `app/javascript/controllers/menu_search_controller.js` | 4 | Stimulus |
| `app/javascript/controllers/section_tabs_controller.js` | 4 | Stimulus |
| `app/javascript/controllers/cart_badge_controller.js` | 4 | Stimulus |
| `app/javascript/controllers/welcome_banner_controller.js` | 4 | Stimulus |
| `app/javascript/controllers/lazy_stripe_controller.js` | 4 | Stimulus |
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

### Modified Files

| File | Phase | Changes |
|---|---|---|
| `Gemfile` | 1 | Add `view_component` gem |
| `app/assets/stylesheets/design_system_2025.scss` | 1 | New tokens (motion, breakpoints, touch, dark mode) |
| `.github/workflows/ci.yml` | 1 | Lighthouse CI job |
| `app/controllers/onboarding_controller.rb` | 2 | Simplify to step 1 only, redirect to restaurant edit |
| `app/models/onboarding_session.rb` | 2 | Remove dead step enums |
| `app/views/onboarding/account_details.html.erb` | 2 | Add data-testid, mobile-first layout |
| `app/views/restaurants/sections/_go_live_progress_2025.html.erb` | 2 | Enhance as canonical onboarding |
| `app/views/restaurants/edit_2025.html.erb` | 2+3 | Auto-expand checklist, breadcrumb, tab bar, remove inline styles |
| `app/javascript/controllers/go_live_progress_controller.js` | 2 | Enhance with onboarding mode |
| `app/views/restaurants/_sidebar_2025.html.erb` | 3 | Expandable groups, mobile hide |
| `app/views/menus/edit_2025.html.erb` | 3 | Remove inline script (~420 lines), wire Stimulus |
| `app/views/menus/sections/_sections_2025.html.erb` | 3 | Sortable + inline edit |
| `app/views/menus/sections/_items_2025.html.erb` | 3 | Sortable + inline edit |
| `app/views/layouts/smartmenu.html.erb` | 4 | Defer Stripe, remove footer for customers |
| `app/views/smartmenus/show.html.erb` | 4 | Section tabs, bottom sheet cart, list layout, skeleton |
| `app/views/smartmenus/_showMenuitemHorizontal.html.erb` | 4 | Replace card with list row, LQIP placeholders |
| `app/views/smartmenus/_showMenuContentCustomer.html.erb` | 4 | Wire list layout + bottom sheet |
| `app/views/smartmenus/_welcome_banner.html.erb` | 4 | Convert to Stimulus |
| `app/controllers/smartmenus_controller.rb` | 4 | Cache-Control headers |
| `app/assets/stylesheets/pages/_smartmenu.scss` | 4 | List rows, action bar, tabs, LQIP, bottom sheet |
| `app/views/smartmenus/_showMenuContentStaff.html.erb` | 5 | Fix duplicate class attr |

### Deleted Files (Phase 2 — Dead Wizard Code)

| File | Reason |
|---|---|
| `app/views/onboarding/show.html.erb` | Wizard layout — replaced by go-live checklist |
| `app/views/onboarding/restaurant_details.html.erb` | Dead wizard step 2 |
| `app/views/onboarding/plan_selection.html.erb` | Dead wizard step 3 |
| `app/views/onboarding/menu_creation.html.erb` | Dead wizard step 4 |
| `app/assets/stylesheets/pages/_onboarding.scss` | Inline wizard styles |

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
- **Offline support** — Service Worker for smartmenu pages (browse menu without connectivity).
- **Native-feel transitions** — View Transitions API for page/section transitions (Chrome 111+).
- **Analytics dashboard redesign** — apply same mobile-first patterns to insights/analytics views.
- **Menu item detail modal** — tap list row to expand full description, allergens, and image gallery.
- **Voice ordering** — Web Speech API for hands-free menu navigation (accessibility + novelty).
