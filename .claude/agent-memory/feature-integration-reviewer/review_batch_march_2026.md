---
name: March 2026 Feature Integration Review
description: Summary of integration findings for the 14 completed features reviewed in March 2026
type: project
---

## Features Reviewed (March 2026)

14 features across three user audiences: restaurant owners/staff, customers, and mellow.menu internal team.

### Critical Integration Findings

1. **Smartmenu Theming** — Theme picker exists in TWO locations (_settings_2025 as a `<select>` dropdown, _form.html.erb as a `<select>`, and _theme_picker.html.erb as a swatch grid partial). Only `_theme_picker.html.erb` uses the full Stimulus `theme-picker-controller` swatch UX. The `_settings_2025` and `_form.html.erb` implementations use a plain `<select>` with `onchange: requestSubmit()`. Feature flag (`smartmenu_theming`) is NOT gating the theme picker in views. User guide says feature requires flag; implementation shows it renders unconditionally.

2. **Floorplan Dashboard & Wait Times** — Neither feature has a navigation entry in the restaurant sidebar (`_sidebar_2025.html.erb`). They are accessible only by direct URL. The Wait Times user guide says it is reachable "via the Floorplan dashboard Wait Times button" — making Floorplan a prerequisite navigation step for Wait Times.

3. **Employee Order Notes** — Named `Ordrnote` in implementation (consistent with platform Ordr naming conventions) but the feature request doc uses `OrderNote` and `order_notes`. The implementation correctly uses `ordrnotes`. The user guide correctly describes `Ordrnote`. Rendered via `render partial: 'ordrnotes/order_notes_section'` in `ordrs/show.html.erb`.

4. **Profit Margins** — Sidebar has "Profitability" entry linking to `edit_restaurant_path(section: 'profitability')` which renders an overview section. The full profit margins dashboard at `/restaurants/:id/profit_margins` and menu optimisations at `/restaurants/:id/menu_optimizations` are not cross-linked from the sidebar. User guide references both routes directly. Navigation gap between the sidebar overview and the standalone dashboard pages.

5. **CRM Sales Funnel** — No entry in global navbar. Accessible via direct URL `/admin/crm/leads`. Admin views exist. Calendly event handler tests present in test suite (referenced in git status).

6. **Demo Booking** — Admin view exists at `app/views/admin/demo_bookings/`. No CRM integration in v1; `demo_bookings` table is standalone. Relationship to CRM Sales Funnel: demo_bookings and CrmLead are separate models with separate admin views; no auto-linking between them identified.

### Terminology Divergence (Feature Request vs Implementation)

- Feature request doc uses `order_notes` / `OrderNote` / `OrderNotePolicy`
- Implementation uses `ordrnotes` / `Ordrnote` / `OrdrnotePolicy` (correct platform convention)
- Both user guide and implementation are consistent with each other

**Why:** The feature request was written before implementation; the implementation engineer correctly applied the platform naming convention.

**How to apply:** When reviewing future feature docs, treat feature request naming as aspirational only; verify implementation naming against the platform's Ordr/Ordritem/Ordrnote conventions.
