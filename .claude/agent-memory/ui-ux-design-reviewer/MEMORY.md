# UI/UX Design Reviewer — Memory Index

## Project
- [project_css_architecture.md](project_css_architecture.md) — CSS layer stack: Bootstrap 5 base, 2025 design system tokens, legacy + 2025 form/card/sidebar partials coexisting
- [project_dual_token_systems.md](project_dual_token_systems.md) — Two competing token systems: Bootstrap $variables (SCSS) vs CSS custom properties (--color-*, --space-*) from design_system_2025.scss

## Admin UI Conventions
- [pattern_admin_page_conventions.md](pattern_admin_page_conventions.md) — Verified layout/badge/table/form conventions across 5+ well-styled admin views

## Rails 7 + Turbo Patterns
- [pattern_button_to_stacking.md](pattern_button_to_stacking.md) — button_to renders <form> block elements; wrap siblings in d-flex gap-1 or add form: { class: 'd-flex' }
- [pattern_link_to_post_rails7.md](pattern_link_to_post_rails7.md) — link_to with data-turbo-method is broken in Rails 7 + Turbo; mutating actions must use button_to

## Design Anti-Patterns
- [pattern_inline_style_abuse.md](pattern_inline_style_abuse.md) — 335 inline style occurrences across 81 view files; most are hardcoded font-size px values and color hex codes
- [pattern_page_scoped_styles.md](pattern_page_scoped_styles.md) — Multiple <style> blocks embedded directly in section partials (_menus_2025, _localization_2025, etc.)
- [pattern_btn_danger_as_primary.md](pattern_btn_danger_as_primary.md) — btn-danger used as the brand primary button throughout auth and marketing views
- [pattern_form_group_row_legacy.md](pattern_form_group_row_legacy.md) — Bootstrap 4 .form-group .row pattern (col-3 label / col-9 input) still present in restaurants/show.html.erb and several show views
- [pattern_duplicate_disabled_btn_style.md](pattern_duplicate_disabled_btn_style.md) — .quick-action-btn.disabled style block duplicated in both _menus_2025 and _localization_2025 partials
- [pattern_badge_bg_vs_text_bg.md](pattern_badge_bg_vs_text_bg.md) — bg-* badge pattern migrated to text-bg-* across most operator views (2 passes complete); ocr_menu_imports uses intentional bg-opacity variants
- [pattern_card_header_heading.md](pattern_card_header_heading.md) — card-header should use fw-semibold directly, not nested h5/h6 with card-title class
- [pattern_data_confirm_legacy.md](pattern_data_confirm_legacy.md) — FULLY MIGRATED 2026-04-04: all data:{confirm:} and link_to method:delete patterns cleared from operator views
- [pattern_edit_view_style_blocks.md](pattern_edit_view_style_blocks.md) — sizes/tips/allergyns edit views had Tailwind-ish <style> blocks (.text-2xl etc); removed 2026-04-04
- [pattern_error_explanation_div.md](pattern_error_explanation_div.md) — id="error_explanation" bare div (scaffold default) should be Bootstrap alert alert-danger with role="alert"
- [pattern_btn_xs_legacy.md](pattern_btn_xs_legacy.md) — btn-xs is Bootstrap 4, removed in Bootstrap 5 — was present in 5 profitability partials, all fixed 2026-04-04
- [pattern_utilities_scss_registry.md](pattern_utilities_scss_registry.md) — Full registry of custom utility classes in _utilities.scss; check here before adding inline styles
- [pattern_agent_workbench_views.md](pattern_agent_workbench_views.md) — agent_workbench/ views reviewed; clean BS5 structure, inline styles and data-confirm fixed 2026-04-04

## Component APIs
- [component_empty_state.md](component_empty_state.md) — EmptyStateComponent: params title(req), description, icon(Symbol/bi-string), action_text, action_url, action_method, compact
- [component_status_badge.md](component_status_badge.md) — shared/_status_badge: params status, label, size(sm/md/lg); maps statuses to Bootstrap text-bg-* variants
- [component_actions_dropdown.md](component_actions_dropdown.md) — shared/_actions_dropdown: params aria_label, button_class, menu_class, items(array of hashes)
- [component_go_live_checklist.md](component_go_live_checklist.md) — GoLiveChecklistComponent: well-structured Bootstrap card with progress bar; good reference pattern

## SCSS Conventions
- [scss_variables_state.md](scss_variables_state.md) — _variables.scss uses Bootstrap 5 defaults verbatim (primary: #007bff — Bootstrap 4 blue, not customised for mellow.menu brand)
- [scss_loading_order.md](scss_loading_order.md) — Load order: variables → bootstrap → enhancements → legacy components → 2025 system → dark mode → themes

## Accessibility Patterns
- [pattern_tab_aria.md](pattern_tab_aria.md) — Bootstrap 5 tabs need aria-controls, aria-selected on triggers and aria-labelledby on panels — reference performance/index.html.erb

## Persistent Findings
- [finding_restaurants_show_legacy.md](finding_restaurants_show_legacy.md) — restaurants/show.html.erb: entire form is read-only disabled fields rendered as a form; should be a definition list or read-only card
- [finding_navbar_duplicate_ids.md](finding_navbar_duplicate_ids.md) — shared/_navbar: two elements with id="navbar-dropdown" and two with id="nav-account-dropdown" — invalid HTML
- [finding_color_palette_mismatch.md](finding_color_palette_mismatch.md) — Bootstrap $primary=#007bff, design_system --color-primary=#2563EB, and btn-danger used as CTA — three competing "primary" colours
