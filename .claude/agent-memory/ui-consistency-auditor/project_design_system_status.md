---
name: project_design_system_status
description: Current state of 2025 design system migration — what is canonical, what is deprecated, what is drifting
type: project
---

As of March 2026, the project is mid-migration from a custom "2025 design system" toward
standard Bootstrap 5. The application.bootstrap.scss comment explicitly marks the 2025
files as "deprecated — migrating to Bootstrap".

## What is canonical (Bootstrap-first)
- Flash/toast messages: `shared/_notices.html.erb` + `flash_controller.js` — single pattern, correct
- Empty states: `EmptyStateComponent` (ViewComponent) + `shared/_empty_state.html.erb` wrapper — correct
- Actions dropdown: `shared/_actions_dropdown.html.erb` — correct, used in 5 places
- Status badge (restaurant management): `shared/_status_badge.html.erb` — correct, BUT only used
  in one place (`_resource_list_2025.html.erb`); admin views ignore it entirely
- Bottom sheet: `shared/_bottom_sheet.html.erb` + `bottom_sheet_controller.js` — correct pattern,
  BUT the cart bottom sheet (`smartmenus/_cart_bottom_sheet.html.erb`) does not use the shared partial
- Tab bar (menu/content navigation): `shared/_mobile_tab_bar.html.erb` + `tab_bar_controller.js` — correct
- Mobile bottom nav (restaurant edit): `restaurants/_mobile_tab_bar.html.erb` + `mobile_tab_bar_controller.js`
  — separate widget, separate controller, not a duplicate (different semantic purpose)

## What is deprecated (but still loaded)
- `_buttons_2025.scss`: Defines `.btn-legacy`, `.btn-loading-legacy` etc. — classes NOT used in any
  view (zero matches). Pure dead CSS. Should be deleted.
- `_cards_2025.scss`: Defines `.card-app`, `.card-grid`, `.count-panel`. `.card-app` is used in
  32 files; `.count-panel` appears in restaurant sections. NOT yet migrated to Bootstrap `.card`.
- `_forms_2025.scss`, `_ocr_2025.scss`, `_sidebar_2025.scss`: Still active, not yet migrated.
- `design_system_2025.scss`: Still active — provides CSS custom property tokens used everywhere.
  Cannot be deleted until all consumers are migrated.

## CSS architecture load order (application.bootstrap.scss)
1. Bootstrap + Bootstrap Icons
2. Legacy components (utilities, navigation, forms, tables, etc.)
3. Phase 2 enhanced UX (skeleton, empty states, image placeholders, welcome banner)
4. Page-specific (home, smartmenu, onboarding)
5. Bootstrap Enhancements (touch targets, btn-ghost, btn-loading, content-card, bulk-action-bar)
6. 2025 Design System (deprecated, still loaded)
7. Phase 1 Foundation (bottom sheet, camera, tab bar, skeleton frame, sommelier, whiskey ambassador)

## Critical structural note
`design_system_2025.scss` defines the CSS custom property tokens (--color-*, --space-*, etc.)
that are consumed by almost every other stylesheet. It cannot be removed without replacing
all token references.
