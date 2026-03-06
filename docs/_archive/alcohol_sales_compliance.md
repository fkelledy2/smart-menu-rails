# Alcohol Sales Compliance

Goal: Enable restaurants to control alcohol sales, tag alcoholic items, surface legal/time restrictions, help staff with age reminders, and flag items visually. Include auto-detection in menu import and audit trails.

## Phases and Tracking
- [ ] Phase 1: Restaurant setting + item alcohol tagging (boolean and ABV/nature), UI cues, age reminder prompt
- [ ] Phase 2: Sale constraints (time windows, day-of-week, legal blackout dates) and enforcement in add-to-order + staff tools
- [ ] Phase 3: Menu import detection of alcoholic items (rules + ML-ready hooks), whitelist for non-alcoholic variants
- [ ] Phase 4: Audit logs for alcohol item orders and staff acknowledgment of age check prompts
- [ ] Phase 5: Config, i18n, admin UX, documentation & tests

## Phase 1 — Settings, Tagging, Visual Cues, Staff Reminder
- Restaurant setting to enable/disable alcohol sales
  - Model: add `Restaurant.allow_alcohol:boolean` (default false).
  - Admin UI: toggle with helper text. If false, alcoholic items are view-only and cannot be added to orders.
- Menu item tagging
  - Model additions on `Menuitem`:
    - `alcoholic:boolean` (default false)
    - `abv:decimal` (nullable, 0..100)
    - `alcohol_classification:string` (enum-like: wine|beer|spirit|cocktail|liqueur|other|non_alcoholic)
    - `alcohol_notes:text` (optional)
  - Validation: if `alcoholic=false`, `abv` must be nil or 0.
- Visual cues
  - Show an Alcohol chip/icon on cards, modals, and line items. For non-alcoholic classification, show "Non‑alcoholic".
- Staff reminder
  - On staff UI when adding alcoholic items: inline reminder "Verify legal age where applicable." Acknowledge-once-per-session to limit fatigue.
- i18n keys
  - `smartmenus.alcohol.flag`, `smartmenus.alcohol.non_alcoholic`, `smartmenus.alcohol.verify_age`.

## Phase 2 — Legal Time/Date Restrictions + Enforcement
- AlcoholPolicy (future) per restaurant with allowed days, time ranges, blackout dates.
- Enforcement in add-to-order: disable alcoholic items outside allowed window; explain reason.
- Staff tools: policy banner.

## Phase 3 — Menu Import Detection (Auto-Tagging)
- Rule-based classifier for sections/items; whitelist for "non-alcoholic" matches.
- ABV extraction via regex.
- Low-confidence queue for review.

## Phase 4 — Audit Logging & Acknowledgements
- Log alcoholic item additions with policy snapshot and staff reminder state.
- Admin export (CSV) of alcohol-related line items.

### Operations
- Staff can acknowledge age check in the order view (staff UI) via the "Acknowledge age check" button. This updates all unacknowledged events for the order.
- Endpoint: `POST /restaurants/:restaurant_id/ordrs/:id/ack_alcohol`
- Audit data: `AlcoholOrderEvent` rows include order, item, restaurant, employee or session, alcoholic flag, ABV, classification, and acknowledgment metadata.

### Reporting
- View: `GET /restaurants/:restaurant_id/alcohol_order_events`
- CSV: `GET /restaurants/:restaurant_id/alcohol_order_events.csv`

## Phase 5 — Config, i18n, Admin UX, Docs, E2E
- Policy editor UX, previews, documentation, translations, and end-to-end tests.

### i18n keys added
- `smartmenus.alcohol.acknowledge_btn`
- `smartmenus.alcohol.acknowledged`
- `smartmenus.ocr.alcohol.override_label`
- `smartmenus.ocr.alcohol.abv`
- `smartmenus.ocr.alcohol.classification`
- `smartmenus.ocr.alcohol.review_needed`
- `smartmenus.ocr.alcohol.overrides_hint`

### OCR override UX
- Each OCR item shows detection badges and a review state.
- Admin can override Alcohol/ABV/Classification; values persist on OCR item metadata and apply during publish.

## Risks & Mitigations
- Detection errors → provide overrides and review queue.
- Jurisdiction variance → flexible policy primitives.
- Reminder fatigue → session acknowledgement.
