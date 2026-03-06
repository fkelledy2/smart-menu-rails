# UI Pattern Audit Matrix

Generated as part of the Bootstrap convergence & localization effort.

---

## 1. Badges

**Shared partial:** `app/views/shared/_status_badge.html.erb`
Uses `text-bg-{variant}` (Bootstrap 5.3) with a variant map:

| Status      | Variant     |
|-------------|-------------|
| active      | `success`   |
| inactive    | `secondary` |
| draft       | `warning`   |
| archived    | `danger`    |
| pending     | `info`      |
| processing  | `info`      |
| completed   | `success`   |
| failed      | `danger`    |

**Coverage:** 124 badge instances across 47 files.

| Area | Files | Notes |
|------|-------|-------|
| Restaurant sections (`_2025`) | `_staff_2025`, `_catalog_2025`, `_localization_2025`, `_menus_2025`, `_settings_2025`, `_import_2025` | Mix of `_status_badge` partial and inline `<span class="badge …">` |
| Menu sections (`_2025`) | `_items_2025`, `_versions_2025`, `_settings_2025` | Inline badges |
| SmartMenu (customer) | `_showMenuitem`, `_showMenuitemHorizontalActionBar`, `_showMenuitemSizes`, `_allergen_combined_modal`, `_menu_section` | Allergen badges use `bg-warning text-dark` + new `.allergen-badge` class |
| Menu item edit | `menuitems/edit_2025` | 6 inline badges |
| Admin views | `discovered_restaurants`, `claim_requests`, `removal_requests`, `cache`, `performance`, `metrics` | Inline badges |
| Dashboards | `bar_dashboard`, `kitchen_dashboard` | Inline badges for ticket status |
| Shared | `_navbar`, `_status_badge`, `_performance_details_table` | Shared partial + inline |

**Recommendation:** Migrate remaining inline badges to use the shared `_status_badge` partial where status semantics apply. Allergen badges are domain-specific and correctly use a dedicated `.allergen-badge` CSS class.

---

## 2. Dropdowns

**Pattern:** Bootstrap 5 dropdowns (`data-bs-toggle="dropdown"`).

| Area | Files | Pattern |
|------|-------|---------|
| SmartMenu table selectors | `_showTableLocaleSelectorStaff`, `_showTableLocaleSelectorCustomer` | Scrollable dropdown with `.dropdown-menu-scrollable` class (migrated from inline styles) |
| SmartMenu staff banner | `_staff_banner.html.erb` | Scrollable dropdown with `.dropdown-menu-scrollable-sm` (migrated) |
| Restaurant sections | `_menus_2025`, `_import_2025`, `_index_frame_2025` | Standard Bootstrap dropdowns |
| Menu item sizes | `_showMenuitemSizes`, `_showMenuitemStaff` | Button group with dropdown |
| Bulk action bars | Multiple `_2025` partials | `<select>` elements inside `.bulk-action-bar` — not dropdown menus |

**Shared CSS classes added:**
- `.dropdown-menu-scrollable` — `max-height: 400px; overflow-y: auto`
- `.dropdown-menu-scrollable-sm` — `max-height: 300px; overflow-y: auto`
- `.dropdown-search-sticky` — sticky search input inside dropdown

**Recommendation:** Dropdowns are consistent. The scrollable pattern is now shared via CSS classes. No further action needed.

---

## 3. Empty States

**Shared component:** `EmptyStateComponent` (ViewComponent) + `app/views/shared/_empty_state.html.erb` wrapper.

| Area | Implementation | Notes |
|------|---------------|-------|
| SmartMenu (customer) | `smartmenus/show.html.erb` | 4 empty state scenarios (no items, filtered out, search, error) — uses locale keys under `smartmenus.empty_states.*` |
| Menu items list | `menus/sections/_items_2025.html.erb` | Uses shared `_empty_state` partial |
| Resource lists | `shared/_resource_list_2025.html.erb` | Uses shared `_empty_state` partial |
| Restaurant index | `restaurants/_index_frame_2025.html.erb` | Uses shared `_empty_state` partial |
| WiFi section | `restaurants/sections/_wifi_2025.html.erb` | Inline empty state |
| OCR imports | `ocr_menu_imports/show.html.erb` | 5 inline empty states |
| Kitchen/Bar dashboards | `kitchen_dashboard/index`, `bar_dashboard/index` | 3 inline empty states each |

**Recommendation:** Migrate inline empty states in OCR imports and dashboard views to use the shared `EmptyStateComponent` for consistency.

---

## 4. Confirmations

**Pattern:** Turbo `turbo_confirm` or `data: { turbo_confirm: "…" }` for destructive actions.

**Coverage:** 56 confirmation instances across 50 files.

| Area | Files | Pattern |
|------|-------|---------|
| Devise | `registrations/edit` | Account deactivation — localized via `t(".deactivateMyAccountAreYouSure")` |
| Resource forms | All `_form.html.erb` partials (20+) | Standard Rails `data: { turbo_confirm: t('.sure') }` on destroy links |
| Restaurant sections | `_menus_2025`, `_staff_2025`, `_import_2025` | Turbo confirm on delete actions |
| Menu sections | `_items_2025`, `_sections_2025` | Turbo confirm on delete actions |
| SmartMenu | `_showModals.erb` (Request Bill modal) | Custom confirmation modal (not `turbo_confirm`) |
| Admin views | Multiple | Standard `turbo_confirm` |
| Shared | `_resource_list_2025.html.erb` | `turbo_confirm` on bulk delete |

**Localization status:**
- Most `_form.html.erb` files use `t('.sure')` or `t('.are_you_sure')` — **already localized**
- SmartMenu Request Bill uses `t('smartmenus.showModals.request_bill_confirm_title')` — **already localized**
- A few admin views may have hardcoded confirmation strings

**Recommendation:** Audit admin views for hardcoded confirmation strings. Customer and restaurant management views are consistently localized.

---

## 5. Inline Styles Summary (post-convergence)

| Area | Remaining | Reason |
|------|-----------|--------|
| SmartMenu customer views | 11 | All JS-toggled (`display:none`, `visibility`) — must remain inline |
| Restaurant `_2025` sections | ~16 embedded `<style>` blocks | Section-specific CSS (hours editor, menu cards, allergen stats, etc.) — scoped to individual partials |
| Devise/Onboarding | 0 | Fully converged |

---

## 6. Localization Summary

| Area | Status |
|------|--------|
| Devise views (`sessions`, `registrations`, `passwords`) | ✅ Fully localized |
| Onboarding (`account_details`) | ✅ Already localized |
| SmartMenu customer views | ✅ Localized (banner, modals, image, allergen modal) |
| Restaurant `_2025` sections | ✅ Already use `t()` helpers extensively |
| Menu `_2025` sections | ✅ AI modal localized, rest already uses `t()` |
| Admin views | ⚠️ Not audited — lower priority |
