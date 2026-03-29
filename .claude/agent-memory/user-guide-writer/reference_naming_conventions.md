---
name: Naming Conventions — UI vs Internal Code
description: User-facing names, internal model names, persona labels, and Flipper flag names for Smart Menu features
type: reference
---

## Order-Related Model Names (intentional non-standard spelling)
- Internal: `Ordr`, `Ordritem`, `Ordrparticipant`, `OrdrAction`, `OdrSplitPayment`
- User-facing: "order", "order item", "participant" — never use internal spelling in guides

## User Personas and Their Access Levels
- **Restaurant Owner** — full restaurant management, menu, settings, billing, reports
- **Manager** — same as owner for operational purposes; can override notes, edit any order
- **Staff / Server** — order view, notes, floor view; limited settings access
- **Kitchen Staff** — order notes (kitchen visibility), kitchen display
- **Customer** — SmartMenu only (QR scan); no login required
- **mellow.menu Admin** — `@mellow.menu` email; JWT tokens, marketing QRs, CRM, system admin
- **Sales Rep** — mellow.menu internal; CRM Kanban board

## Feature Flag Names (Flipper)
- `qr_security_v1` — QR token + dining session enforcement
- `auto_pay` — Auto Pay & Leave (per restaurant, off by default)
- `receipt_email` — Branded receipt email sending
- `receipt_sms` — SMS receipt (stretch feature)
- `floorplan_dashboard` — Floorplan Dashboard
- `menu_experiments` — A/B Experiments
- `smartmenu_theming` — Theme picker on SmartMenu
- `jwt_api_access` — JWT-protected API endpoints
- `partner_integrations` — Partner integration adapters
- `crm_sales_funnel` — CRM Kanban board (admin-only)

## Key UI Path Patterns
- Menu edit page: `/restaurants/:id/menus/:menu_id/edit`
- SmartMenu customer view: `/t/:public_token`
- Floorplan: `/restaurants/:id/floorplan`
- Profit margins: `/restaurants/:id/profit_margins`
- Menu optimisations: `/restaurants/:id/menu_optimizations`
- A/B experiments: `/restaurants/:restaurant_id/menus/:menu_id/experiments`
- Admin CRM: `/admin/crm/leads`
- Admin JWT tokens: `/admin/jwt_tokens`
- Admin marketing QRs: `/admin/marketing_qr_codes`

## SmartMenu vs Smartmenu
- "SmartMenu" (capital M) appears to be the user-facing product name in documentation
- `Smartmenu` (lowercase m) is the Rails model name
- Use "SmartMenu" or "digital menu" in user guides
