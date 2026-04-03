# UI/UX Design Reviewer — Memory Index

## Project
- [project_css_architecture.md](project_css_architecture.md) — CSS layer stack: Bootstrap 5 base, 2025 design system tokens, legacy + 2025 form/card/sidebar partials coexisting
- [project_dual_token_systems.md](project_dual_token_systems.md) — Two competing token systems: Bootstrap $variables (SCSS) vs CSS custom properties (--color-*, --space-*) from design_system_2025.scss

## Admin UI Conventions
- [pattern_admin_page_conventions.md](pattern_admin_page_conventions.md) — Verified layout/badge/table/form conventions across 5+ well-styled admin views

## Design Anti-Patterns
- [pattern_inline_style_abuse.md](pattern_inline_style_abuse.md) — 335 inline style occurrences across 81 view files; most are hardcoded font-size px values and color hex codes
- [pattern_page_scoped_styles.md](pattern_page_scoped_styles.md) — Multiple <style> blocks embedded directly in section partials (_menus_2025, _localization_2025, etc.)
- [pattern_btn_danger_as_primary.md](pattern_btn_danger_as_primary.md) — btn-danger used as the brand primary button throughout auth and marketing views
- [pattern_form_group_row_legacy.md](pattern_form_group_row_legacy.md) — Bootstrap 4 .form-group .row pattern (col-3 label / col-9 input) still present in restaurants/show.html.erb and several show views
- [pattern_duplicate_disabled_btn_style.md](pattern_duplicate_disabled_btn_style.md) — .quick-action-btn.disabled style block duplicated in both _menus_2025 and _localization_2025 partials

## Component APIs
- [component_empty_state.md](component_empty_state.md) — EmptyStateComponent: params title(req), description, icon(Symbol/bi-string), action_text, action_url, action_method, compact
- [component_status_badge.md](component_status_badge.md) — shared/_status_badge: params status, label, size(sm/md/lg); maps statuses to Bootstrap text-bg-* variants
- [component_actions_dropdown.md](component_actions_dropdown.md) — shared/_actions_dropdown: params aria_label, button_class, menu_class, items(array of hashes)
- [component_go_live_checklist.md](component_go_live_checklist.md) — GoLiveChecklistComponent: well-structured Bootstrap card with progress bar; good reference pattern

## SCSS Conventions
- [scss_variables_state.md](scss_variables_state.md) — _variables.scss uses Bootstrap 5 defaults verbatim (primary: #007bff — Bootstrap 4 blue, not customised for mellow.menu brand)
- [scss_loading_order.md](scss_loading_order.md) — Load order: variables → bootstrap → enhancements → legacy components → 2025 system → dark mode → themes

## Persistent Findings
- [finding_restaurants_show_legacy.md](finding_restaurants_show_legacy.md) — restaurants/show.html.erb: entire form is read-only disabled fields rendered as a form; should be a definition list or read-only card
- [finding_navbar_duplicate_ids.md](finding_navbar_duplicate_ids.md) — shared/_navbar: two elements with id="navbar-dropdown" and two with id="nav-account-dropdown" — invalid HTML
- [finding_color_palette_mismatch.md](finding_color_palette_mismatch.md) — Bootstrap $primary=#007bff, design_system --color-primary=#2563EB, and btn-danger used as CTA — three competing "primary" colours
