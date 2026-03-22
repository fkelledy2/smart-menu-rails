---
name: project_widget_inventory
description: Canonical locations and known divergences for each widget type — established in March 2026 audit
type: project
---

## Flash / Toast Messages
- Canonical: `app/views/shared/_notices.html.erb` + `app/javascript/controllers/flash_controller.js`
- Pattern: Bootstrap `.toast` with `text-bg-{variant}`, auto-show via Stimulus on connect
- Host: `app/views/layouts/application.html.erb` (toast-container, bottom-right)
- The smartmenu layout (`layouts/smartmenu.html.erb`) does NOT include the toast container — flash
  messages will not render on the customer-facing smartmenu pages.

## Empty States
- Canonical ViewComponent: `app/components/empty_state_component.rb`
- Thin partial wrapper: `app/views/shared/_empty_state.html.erb`
- CSS: `app/assets/stylesheets/components/_empty_states.scss`
- Well-used in restaurant sections (_menus_2025, _allergens_2025, _tables_2025, _staff_2025,
  _localization_2025, _sizes_2025) and menus sections (_items_2025, _sections_2025, _versions_2025,
  _qrcode_2025)
- DIVERGENCE: kitchen_dashboard/index and bar_dashboard/index use an ad-hoc inline div
  with class="empty-state" (not the component) for their per-column empty states. These are
  intentionally inline/dynamic (toggled via JS by the dashboard's real-time ActionCable updates)
  so a full component extraction may not be appropriate without JS refactor.

## Status Badges
- Canonical partial: `app/views/shared/_status_badge.html.erb`
  Maps status strings to Bootstrap `text-bg-{variant}` badges.
- DIVERGENCE (Major): Only used in ONE place (`_resource_list_2025.html.erb`).
  Every other status badge in the codebase (admin views, profit_margins, hero_images,
  ordrs, menuitems, etc.) is written inline with ad-hoc `bg-*` classes.
- Two Bootstrap badge class families in use simultaneously:
  * Old: `bg-success`, `bg-danger`, `bg-warning text-dark` (Bootstrap 4 style, still valid in BS5)
  * New: `text-bg-success`, `text-bg-danger`, `text-bg-warning` (Bootstrap 5.2+ correct style)
  * Both render correctly but inconsistently.

## Modals
- No canonical modal component or partial. Modals are implemented ad-hoc throughout.
- Patterns found:
  1. `_allergen_combined_modal.html.erb` — `modal-dialog-centered`, inline `<script>` block
  2. `_add_note_modal.html.erb` — `modal-lg`, inline `<script>` for char counter
  3. `_welcome_modal.html.erb` — `modal-sm`, inline `<script>` for auto-dismiss
  4. `_modal_header_add_item.erb` / `_modal_footer_add_item.erb` / `_modal_footer_primary.erb`
     — smartmenu modals split into header/footer partials (unique pattern)
  5. `restaurants/_new_modal_form.html.erb` — turbo_frame_tag wrapping a form partial
  6. Various other modals in menus/sections and restaurant sections
- All use standard Bootstrap `.modal.fade` / `.modal-dialog` / `.modal-content` structure.
- Inconsistency: modal title heading level varies — h1.fs-5 vs h5.modal-title
- Inconsistency: close button aria-label — some use t('common.close'), some hardcode "Close"
- Inconsistency: some modals embed `<script>` blocks (allergen, add_note, welcome), some use
  Stimulus controllers. The allergen modal is a prime candidate for Stimulus extraction.

## Cards
- Two active card systems:
  1. Bootstrap `.card` (vanilla) — used in kitchen_dashboard, bar_dashboard, admin views, many tables
  2. Custom `.card-app` (from `_cards_2025.scss`) — used in 32 view files across restaurant sections
  3. Custom `.content-card` (from `_bootstrap_enhancements.scss`) — layout wrapper, ~34 files
- `.card-app` is the "canonical" card for the restaurant management UI, but it is not a
  ViewComponent — it is raw HTML with CSS class.

## Buttons / CTAs
- Two button systems loaded simultaneously:
  1. Bootstrap `.btn`, `.btn-primary`, `.btn-sm`, etc. — used in virtually all views
  2. Custom `.btn-legacy` system (`_buttons_2025.scss`) — NOT USED in any view (dead CSS)
  3. Custom `.btn-ghost` (`_bootstrap_enhancements.scss`) — extends Bootstrap, actively used
  4. Custom `.btn-loading` (`_bootstrap_enhancements.scss`) — spinner state, actively used
  5. `.btn-loading-legacy` (`_buttons_2025.scss`) — NOT USED (dead CSS, duplicate of .btn-loading)
- All active button usage is correctly Bootstrap-based.

## Skeleton / Loading States
- Two separate skeleton systems:
  1. `_skeleton_loading.scss` + `smartmenus/_skeleton_loading.html.erb` — shimmer animation,
     complex card skeletons, used only on smartmenu customer page
  2. `_skeleton_frame.scss` — `.skeleton-shimmer` class + `turbo-frame[busy]` global rule,
     simpler system for Turbo Frame loading
- The two systems define their shimmer `@keyframes` independently with different names
  (`skeleton-loading` vs `skeleton-shimmer`) and slightly different gradient stops.
- The `turbo-frame[busy]` rule in `_skeleton_frame.scss` is global and affects ALL turbo frames.

## Tab Bars / Navigation
- Two distinct tab bar widgets (different semantic purposes, correctly separated):
  1. `shared/_mobile_tab_bar.html.erb` + `tab_bar_controller.js` — horizontal scrollable tab bar
     for content-section navigation (used in menus edit, potentially restaurant edit on desktop).
     Styled via `_tab_bar.scss`.
  2. `restaurants/_mobile_tab_bar.html.erb` + `mobile_tab_bar_controller.js` — fixed bottom nav
     bar for restaurant edit page on mobile. Styled via `.mobile-tab-bar-item` in `_sidebar_2025.scss`.
- Only the restaurant-specific one is currently wired up (edit_2025.html.erb:87).
- The shared `_mobile_tab_bar.html.erb` partial has no confirmed call sites in views (0 matches
  for `render.*shared/mobile_tab_bar`). It may be unused or called from a controller partial.

## Bottom Sheet
- Single Stimulus controller: `bottom_sheet_controller.js` — correct, one controller
- Two HTML implementations:
  1. `shared/_bottom_sheet.html.erb` — generic reusable partial, accepts locals
  2. `smartmenus/_cart_bottom_sheet.html.erb` — cart-specific, does NOT render the shared partial;
     it duplicates the `.bottom-sheet` container, handle, and backdrop directly.
- The cart bottom sheet has significantly more complex HTML (summary bar, start-order button,
  item list, totals) that cannot simply be extracted to the generic partial without a content
  slot/block mechanism. The structural duplication of the `.bottom-sheet__handle-bar` and
  `.bottom-sheet-backdrop` is the actionable redundancy.

## Dropdowns / Actions
- Canonical: `shared/_actions_dropdown.html.erb` — three-dots button + Bootstrap dropdown
- Used correctly in 5 places: `_resource_list_2025`, `_items_2025`, `_sections_2025`,
  `_menus_2025`, `_staff_2025`
- Many other views use inline Bootstrap dropdown markup without the shared partial.

## Flash / Alert Inline (within-page alerts)
- `alert alert-info`, `alert alert-warning`, `alert alert-danger` used inline throughout many
  views for contextual messages (not flash). This is correct Bootstrap usage.
- No standardisation needed here — inline alerts are context-specific.

## CSS Media Query Violations (SassC incompatibility)
- Range syntax `@media (width <= N)` and `@media (width >= N)` found in 19 Sass files.
- This is a known recurring issue (two prior fix commits). The syntax compiles with Dart Sass
  but FAILS with SassC. All must be `@media (max-width: N)` / `@media (min-width: N)`.
- Affected files include: _skeleton_loading.scss, _buttons_2025.scss, _cards_2025.scss,
  _forms_2025.scss, _sidebar_2025.scss, _bootstrap_enhancements.scss, _smartmenu_mobile.scss,
  _empty_states.scss, _utilities.scss, _tables.scss, _order_notes.scss, _image_placeholders.scss,
  _split_bill.scss, _scrollbars.scss, _welcome_banner.scss, _ocr_2025.scss, _navigation.scss,
  pages/_home.scss, pages/_smartmenu.scss.

## Inline Styles (anti-pattern)
- `shared/_resource_list_2025.html.erb` uses `style="width: 300px;"` on its search input.
  Should be a CSS class.
- `shared/_footer.html.erb` uses `style="font-size: 0.65rem;"` twice.
- The allergen modal uses `style="display: none;"` on check icons — toggled by inline JS.
  Should be a utility class.
- `smartmenus/show.html.erb` uses inline `<style>` blocks for test-env modal overrides.
  These are test-only and acceptable as-is.

## Inline `<script>` Blocks in Partials
- `restaurants/_welcome_modal.html.erb` — modal init + auto-dismiss logic (should be Stimulus)
- `ordrnotes/_add_note_modal.html.erb` — character counter (should be Stimulus)
- `smartmenus/_allergen_combined_modal.html.erb` — full allergen filter logic (should be Stimulus)
- `smartmenus/show.html.erb` — test-env button enabler (acceptable, test-only)
- `shared/_resource_list_2025.html.erb` — inline `<style>` block (should be a Sass partial)
