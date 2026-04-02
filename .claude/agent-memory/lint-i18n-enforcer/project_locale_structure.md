---
name: Locale file structure
description: How locale files are organised in the Smart Menu codebase
type: project
---

Locale files live under `config/locales/{locale}/` subdirectories (e.g. `config/locales/en/`).

Each feature area has its own file named `{feature}.{locale}.yml`. The current English set includes (among others):
- `employees.en.yml` — employee CRUD + new role-change sections (`change_role_form`, `role_history`, `controller`)
- `employee_mailer.en.yml` — transactional emails for employee role changes (added 2026-04-02)
- `restaurants_sections.en.yml` — all restaurant settings section partials, keyed by section name (`staff_2025`, `tables_2025`, etc.)
- `smartmenus.en.yml` — customer-facing smart menu UI, including `ordritem_tracking` (added 2026-04-01)
- `kitchen_dashboard.en.yml` — kitchen dashboard operator UI (created 2026-04-01); keys added 2026-04-02: `station_ticket_card.order_number`, `time_ago`, `kitchen_notes_count` (pluralised), `advance_to_status`; `index.empty_preparing_tickets`, `index.empty_ready_tickets`

**Key naming convention:** `{controller_or_feature}.{sub_section}.{key}`

For relative `t('.')` calls inside partials the path resolves to the partial's view path:
- `_staff_2025.html.erb` → `restaurants.sections.staff_2025.*`
- `_change_role_form.html.erb` → use absolute keys (`t('employees.change_role_form.*')`) since the partial is shared

**Why:** These locale files are fed into a DeepL translation pipeline; new keys in `en/` must be flagged for translation. Do not auto-translate to other locales.

**How to apply:** When adding a new feature, create `config/locales/en/{feature}.en.yml` and add absolute key paths in controllers; use relative `t('.')` only in view partials that live under a conventional path.
