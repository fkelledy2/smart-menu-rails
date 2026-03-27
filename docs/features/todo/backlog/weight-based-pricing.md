# Weight-Based Menu Item Pricing

## Status
- Priority Rank: #30
- Category: Post-Launch
- Effort: M
- Dependencies: Existing `Menuitem` model, existing `Ordritem` model, existing SmartMenu customer ordering UI, Kitchen Display System (KDS)

## Problem Statement
Premium restaurants — fine dining, butchers, seafood counters, and steakhouses — routinely price certain items by weight (e.g. a ribeye at €4.50 per 100g). The current `Menuitem` model supports only a fixed price per item. This forces these restaurants to either list a fixed price for a "standard" portion (losing flexibility) or to avoid mellow.menu altogether. Adding weight-based pricing extends the platform's addressable market to premium dining segments and enables upselling by portion size.

## Success Criteria
- Restaurant managers can configure any menu item with weight-based pricing by setting a price per unit (e.g. per 100g)
- Customers see the per-unit price and a weight selector on the SmartMenu ordering UI; the total price updates in real time as they adjust the weight
- Kitchen staff see the ordered weight prominently on the Kitchen Display System
- Order totals are calculated correctly from the ordered weight before payment is taken
- Weight-based items are clearly distinguished from standard items in both the back-office UI and the customer-facing menu

## User Stories
- As a restaurant manager, I want to configure my ribeye steak at €4.50 per 100g with a range of 150g–600g and a default of 300g, so customers can order their preferred portion and the price is always accurate.
- As a customer, I want to see "€4.50 / 100g" and a weight selector that shows me my total price as I adjust the portion, so I know exactly what I'm ordering before I confirm.
- As a kitchen staff member, I want to see "300g" displayed prominently on the order ticket so I prepare the correct portion without having to do mental arithmetic.
- As a restaurant manager, I want weight-based items clearly marked in my menu management UI so I can tell at a glance which items use variable pricing.

## Functional Requirements
1. `Menuitem` gains a `pricing_type` enum column: `standard` (default, existing behaviour) and `weight_based`.
2. Weight-based items require: `price_per_unit` (decimal), `weight_unit` (string, e.g. `"100g"`), `min_weight` (decimal), `max_weight` (decimal), `default_weight` (decimal).
3. The menu item form in the back office shows a pricing type toggle. Selecting "Weight-based" reveals the weight configuration fields.
4. The SmartMenu customer ordering UI, for weight-based items, renders a weight selector with: the per-unit price displayed, a numeric input or slider bounded by min/max, preset portion size buttons if configured, and a running total that updates instantly.
5. Weight updates on the customer UI happen client-side (Stimulus controller) — no server round-trip required for the price calculation.
6. On order submission, the `Ordritem` records the `ordered_weight` and the `calculated_price` at the time of order. The calculated price is locked on submission and is not recalculated later.
7. The Kitchen Display System shows `ordered_weight` prominently (e.g. in bold, distinct from item name).
8. The order total displayed to the customer and on receipts uses `Ordritem#calculated_price` — consistent whether weight-based or standard.
9. A server-side price re-validation occurs on order submission: if `calculated_price` in the request differs from what the server calculates for the submitted `ordered_weight` by more than €0.01 (floating-point tolerance), the server rejects the submission with an error. This prevents client-side price manipulation.
10. Weight-based items in the menu management list are annotated with a "per-weight" badge.

## Non-Functional Requirements
- Price calculations on the server use integer arithmetic in cents to avoid floating-point precision errors. `price_per_unit` is stored as decimal(10,2) but all arithmetic is done in integer cents.
- `ordered_weight` must be positive, within the item's configured `min_weight`–`max_weight` range, and validated on the server — not just client-side.
- The weight selector Stimulus controller must be accessible: keyboard-operable, screen-reader compatible, no reliance on mouse-only gestures.
- No new JS framework — the weight selector is a Stimulus controller targeting a standard range input + number input combo.
- Existing standard-priced items are completely unaffected by this change — `pricing_type` defaults to `standard` and the weight fields are null/ignored.

## Technical Notes

### Model: Menuitem
```ruby
# New migration
add_column :menuitems, :pricing_type, :integer, null: false, default: 0
add_column :menuitems, :price_per_unit, :decimal, precision: 10, scale: 2
add_column :menuitems, :weight_unit, :string          # '100g', '50g', '1kg', etc.
add_column :menuitems, :min_weight, :decimal, precision: 8, scale: 2
add_column :menuitems, :max_weight, :decimal, precision: 8, scale: 2
add_column :menuitems, :default_weight, :decimal, precision: 8, scale: 2
add_index  :menuitems, :pricing_type

enum :pricing_type, { standard: 0, weight_based: 1 }
```

Validations to add to `Menuitem`:
```ruby
validates :price_per_unit, :weight_unit, :min_weight, :max_weight, :default_weight,
          presence: true, if: :weight_based?
validates :min_weight, numericality: { greater_than: 0 }, if: :weight_based?
validates :max_weight, numericality: { greater_than: :min_weight }, if: :weight_based?
validates :default_weight, numericality: {
  greater_than_or_equal_to: :min_weight,
  less_than_or_equal_to: :max_weight
}, if: :weight_based?
```

### Model: Ordritem
```ruby
add_column :ordritems, :ordered_weight, :decimal, precision: 8, scale: 2
# null for standard-priced items; present for weight-based items
# calculated_price already exists on Ordritem (confirm column name before migration)
```

### Service to create/modify
`app/services/menuitems/weight_price_calculator_service.rb`:
- `calculate(menuitem, weight_grams)` — returns price in cents as integer
- Used both client-side (via a data attribute on the Stimulus controller) and server-side for validation on order submission

The server-side validation belongs in the existing `Ordritems::CreateService` (or equivalent) — add a weight validation step when `menuitem.weight_based?`.

### Stimulus controller
`app/javascript/controllers/weight_price_controller.js`:
- Targets: weight input, price display, add-to-cart button
- Reads `data-price-per-unit`, `data-weight-unit`, `data-min-weight`, `data-max-weight` from the element
- Updates the displayed price as the weight input changes
- Disables the add-to-cart button if weight is outside min/max

### Pundit policy
No new policy required — `MenuitemPolicy` already controls menu item CRUD. Add `weight_based?` check to the Pundit scope if needed to restrict weight-based pricing to specific plan tiers.

### Flipper flag
- `weight_based_pricing` — gates the pricing type toggle in the back office and the weight selector UI in SmartMenu

### Kitchen Display System
The existing KDS view for `Ordritem` needs a conditional block: if `ordered_weight.present?`, display weight prominently. No new model or service needed — it's a view change only.

### No `actual_weight` field in v1
The raw spec proposed an `actual_weight` field for kitchen staff to record the actual weighed portion and trigger a price adjustment. This creates significant complexity around payment re-capture and receipt amendments. Defer to v2.

## Acceptance Criteria
1. A restaurant manager can toggle a menu item to "weight-based", set €4.50 per 100g, min 150g, max 600g, default 250g, and save successfully.
2. Attempting to save a weight-based item without `price_per_unit` fails validation with a clear error message.
3. In SmartMenu, a weight-based item displays "€4.50 / 100g" and a weight selector defaulting to 250g showing "€11.25 total".
4. Adjusting the weight selector to 300g instantly updates the displayed total to "€13.50" without a page reload.
5. Attempting to submit an order with `ordered_weight` outside the configured min/max fails on the server with a validation error.
6. Attempting to submit a manipulated `calculated_price` that differs from the server's calculation by more than €0.01 is rejected.
7. The KDS view for a weight-based order item shows the `ordered_weight` prominently alongside the item name.
8. An existing standard-priced item is completely unaffected — no behaviour change, no new fields shown.
9. The `weight_based_pricing` Flipper flag, when disabled, hides the pricing type toggle in the back office; all existing items continue to work.
10. The weight selector Stimulus controller is operable via keyboard alone (tab to input, type weight, total updates).

## Out of Scope
- Kitchen staff recording actual weighed portion and triggering price adjustments (v2)
- Weight-based pricing in bulk menu import (OCR import) — weight fields would be left null
- Volume discounts (e.g. lower per-unit price for larger weights)
- Weight unit conversion (metric only in v1; no imperial)

## Open Questions
1. Should weight-based pricing be gated to a specific plan tier (e.g. Pro and above)? Recommend yes — confirm which tier.
2. What weight units should be supported in v1? Spec assumes grams-based units (`50g`, `100g`, `1kg`). Should ounces/pounds be supported for non-metric markets?
3. Is there a `calculated_price` column already on `Ordritem`, or is only `unit_price` present? Confirm the column name before writing the migration.
