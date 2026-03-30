---
name: Smart Menu Navigation Structure
description: How the platform surfaces navigation — which elements live where, and how new features should hook in
type: reference
---

## Primary Navigation Layers

### 1. Global Navbar (`app/views/shared/_navbar.html.erb`)
- Bootstrap 5 `navbar-expand-md` with `navbar-light bg-light`
- Left: Restaurants dropdown (links to `restaurants_path` and quick-links to recent restaurants)
- Right: Dark mode toggle (theme-toggle Stimulus controller), User account dropdown
- Admin items in account dropdown: Madmin dashboard, Act as user, Crawl a City, Discovery Queue, Change Detection Queue, Marketing QR Codes, Testimonials, Hero Images, Feature Flags
- CRM, JWT Tokens, and Demo Bookings are NOT in the global navbar — they live only under `/admin/` namespace
- No "Floorplan" or "Wait Times" entries in the global navbar

### 2. Restaurant Sidebar (`app/views/restaurants/_sidebar_2025.html.erb`)
- Sections: RESTAURANT (Details, Schedule, Localization), MENUS (All Menus, Allergens, Sizes, Settings), PROFITABILITY (Overview), OPERATIONS (collapsible: Staff, Tables, Kitchen, Bar Dashboard, Taxes & Tips, Ordering, Insights, Jukebox, WiFi), SUPER ADMIN (Advanced)
- Uses `data-turbo-frame="restaurant_content"` for in-page navigation via Turbo Frames
- No "Floorplan" link in sidebar — Floorplan is a standalone page at `/restaurants/:id/floorplan`
- No "Wait Times" link in sidebar — navigable from Floorplan page header when flag enabled
- Profitability section links to `edit_restaurant_path(section: 'profitability')` — not directly to `/profit_margins`

### 3. Menu Sidebar (`app/views/menus/_sidebar_2025.html.erb`)
- Sections: MENU (Details, Schedule), CONTENT (Sections, Items), SETUP (Settings, QR Code, Versions, Profitability, A/B Experiments)
- A/B Experiments link is Flipper-gated: `Flipper.enabled?(:menu_experiments, restaurant)`
- A/B Experiments uses `data-turbo-frame="_top"` (full page navigation, unlike other links)
- Theme picker lives in SETUP > Settings section of menu edit page (not a dedicated sidebar link)

### 4. Admin Namespace (`/admin/`)
- Admin features: CRM Sales Funnel (`/admin/crm/leads`), JWT Tokens (`/admin/jwt_tokens`), Marketing QR Codes (`/admin/marketing_qr_codes`), Demo Bookings (`/admin/demo_bookings`)
- Admin views exist at `app/views/admin/`
- No dedicated admin navigation partial identified — admin nav appears to rely on the global navbar dropdown
