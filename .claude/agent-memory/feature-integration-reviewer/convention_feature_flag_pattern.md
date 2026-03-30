---
name: Flipper Feature Flag UI Conventions
description: How Flipper flags are used to gate UI visibility across Smart Menu, and known inconsistencies
type: reference
---

## Established Convention

Feature flags gate UI visibility in views using `Flipper.enabled?(:flag_name, restaurant)`.
Example: `app/views/menus/_sidebar_2025.html.erb` gates the A/B Experiments link.

## Flags and Their UI Impact

| Flag | Gate Location | Navigation Entry Point |
|------|--------------|----------------------|
| `menu_experiments` | Sidebar view | Menu sidebar shows "A/B Experiments" link |
| `floorplan_dashboard` | No view gate found | Accessed directly via URL; no nav entry |
| `wait_time_estimation` | No view gate found | Linked from Floorplan page header |
| `smartmenu_theming` | NOT gated in views | Theme picker renders unconditionally |
| `auto_pay` | No dedicated UI gate found | Renders if Flipper flag enabled (runtime) |
| `receipt_email` | No UI gate found | Button visible only for paid/closed orders |
| `menu_experiments` | Menu sidebar Flipper check | Correct pattern |
| `jwt_api_access` | Not visible in restaurant UI | Admin-only feature |
| `partner_integrations` | Not visible in restaurant UI | API-only, no UI found |
| `crm_sales_funnel` | Not visible in global nav | Admin-only, accessed directly |
| `qr_security_v1` | Not visible as UI toggle | Infrastructure change, transparent to users |

## Known Inconsistency

The `smartmenu_theming` Flipper flag is documented in the feature spec and user guide as required, but the theme picker (`_settings_2025.html.erb`, `_form.html.erb`) renders unconditionally — there is no `Flipper.enabled?(:smartmenu_theming, ...)` check wrapping the theme UI in the views found during the March 2026 review.
