---
name: CSS Architecture Overview
description: The full stylesheet loading stack — Bootstrap 5 base, 2025 token system, legacy and 2025 component partials coexisting
type: project
---

The stylesheet pipeline is defined in application.bootstrap.scss and loads in this order:

1. themes/_variables.scss — Bootstrap variable overrides (currently near-default values)
2. Bootstrap 5 core + bootstrap-icons
3. jumpstart/announcements
4. Legacy components: utilities, navigation, forms, tables, scrollbars, smartmenu_mobile, split_bill, order_notes
5. Phase 2 enhanced UX: skeleton_loading, empty_states, image_placeholders, welcome_banner
6. Page-specific: pages/home, pages/smartmenu, pages/onboarding
7. utility.scss
8. components/bootstrap_enhancements (touch targets, btn-ghost, btn-loading, content-card)
9. design_system_2025.scss (CSS custom property token system — marked as deprecated, migrating to Bootstrap)
10. 2025 component partials: forms_2025, cards_2025, ocr_2025, sidebar_2025, resource_list
11. Dark mode overrides
12. Named smartmenu themes (modern/rustic/elegant)
13. Phase 1 foundation: bottom_sheet, camera_capture, tab_bar, skeleton_frame, sommelier, whiskey_ambassador

Plus inline dropdown z-index hacks at the bottom of application.bootstrap.scss.

**Why:** This layered architecture means there are multiple competing class systems for the same UI patterns (e.g., .card-app vs .card vs .content-card for cards; .form-control-legacy vs .form-control for inputs).

**How to apply:** When reviewing any component, check which layer its styles come from. The 2025 files (forms_2025, cards_2025, sidebar_2025) should be the target state; legacy files and _variables.scss need updating to align.
