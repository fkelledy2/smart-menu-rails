# Wine Multi-Pricing — Development Specification

**Status:** Draft for review
**Date:** 2026-02-22
**Author:** Cascade (AI pair programmer)

---

## 1. Overview

Extend Smart Menu to support **wine-bar-style multi-unit pricing** — where a single wine can be purchased by the **bottle**, **glass** (standard or large), **half-bottle**, or **carafe**. This touches four layers:

1. **Data model** — new wine-specific serving sizes + per-size prices
2. **Import pipeline** — GPT extracts per-size prices; staging stores them; confirm creates size mappings
3. **Customer ordering UX** — prominent size selector (not a hidden dropdown) for wines
4. **Order tracking** — record which size was ordered on each line item

---

## 2. Design Decisions (Sensible Defaults)

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Wine serving sizes | `bottle`, `glass`, `large_glass`, `half_bottle`, `carafe` | Covers 95%+ of European wine bars |
| Reuse existing `Size` model? | **Yes** — add a `category` enum (`general`, `wine`) | Avoids a parallel model; wine sizes are auto-created per restaurant |
| Default price field | `Menuitem.price` = **bottle price** (or lowest available) | Bottle is the canonical reference price for wines |
| OcrMenuItem multi-price storage | Use existing `metadata` JSONB column: `{ "size_prices": { "bottle": 45.0, "glass": 9.0 } }` | No migration needed for staging table |
| Ordritem size tracking | Add `size_name` string column to `ordritems` | Lightweight; no FK needed; survives size deletion |
| Customer UX | Inline pill/chip selector below price (not dropdown) for wine items | More visible; industry standard for wine apps |
| GPT prompt changes | Request structured `size_prices` object for wine items | Single item with multiple prices, not duplicate items |

---

## 3. Phased Implementation Plan

### Phase W-P1: Schema & Seed Data
**Goal:** Database ready for wine sizes and order size tracking.

#### 3.1.1 Migration: Add `category` to `sizes`
```ruby
add_column :sizes, :category, :string, default: 'general', null: false
add_index :sizes, [:restaurant_id, :category]
```

#### 3.1.2 Migration: Add `size_name` to `ordritems`
```ruby
add_column :ordritems, :size_name, :string
```

#### 3.1.3 Seed: Auto-create wine sizes
When a restaurant has `establishment_types` including `wine_bar`, auto-create canonical wine `Size` records if they don't exist:

| name | size enum | category |
|------|-----------|----------|
| Bottle (750ml) | xl | wine |
| Half Bottle (375ml) | lg | wine |
| Carafe (500ml) | lg | wine |
| Glass (175ml) | md | wine |
| Large Glass (250ml) | md | wine |

This runs as a service (`WineSizeSeeder.seed!(restaurant)`) called:
- On restaurant creation/update when `wine_bar` is added to `establishment_types`
- During import when wine items are detected

#### 3.1.4 Model changes

**Size model:**
```ruby
# Add to Size model
enum :category, { general: 'general', wine: 'wine' }, default: :general

scope :wine, -> { where(category: :wine) }
scope :general, -> { where(category: :general) }
```

**Ordritem model:**
```ruby
# Add to Ordritem
# size_name: string — e.g. "Bottle (750ml)", "Glass (175ml)"
```

**Menuitem model:**
```ruby
# Add helper method
def wine_size_mappings
  menuitem_size_mappings.joins(:size).where(sizes: { category: :wine }).includes(:size)
end

def has_wine_sizes?
  wine? && wine_size_mappings.any?
end
```

---

### Phase W-P2: Import Pipeline — GPT Multi-Price Extraction
**Goal:** GPT extracts per-size wine prices; stored in OcrMenuItem staging.

#### 3.2.1 Update GPT prompt in `WebMenuProcessor#build_venue_context`

Replace the current wine bar guidance:
```
WINE LIST GUIDANCE:
- For each wine, include the full wine name (producer + cuvée if available).
- Include vintage year, grape/blend, and region/appellation in the description.
- If multiple serving sizes are listed (bottle, glass, carafe, half bottle, large glass),
  include ALL prices in a "size_prices" object on the item.
- Do NOT create separate items for different sizes of the same wine.
- Use the schema:
  {
    "name": "Château Margaux 2015",
    "description": "Bordeaux, Cabernet Sauvignon blend, 14% ABV",
    "price": 180.00,
    "size_prices": {
      "bottle": 180.00,
      "glass": 18.00,
      "large_glass": 24.00,
      "half_bottle": 95.00,
      "carafe": 120.00
    },
    "allergens": ["sulphites"]
  }
- "price" should be the bottle price (or the first/primary price listed).
- Only include size keys that have prices on the menu. Omit sizes not listed.
- Use sections like "Red Wines", "White Wines", "Sparkling", "Rosé".
```

Also update the JSON schema in the main prompt to include the optional `size_prices` field:
```json
{
  "name": "<item name>",
  "description": "<item description or empty>",
  "price": "<numeric price or null>",
  "size_prices": { "bottle": null, "glass": null, "large_glass": null, "half_bottle": null, "carafe": null },
  "allergens": ["gluten", "dairy", ...]
}
```

#### 3.2.2 Update `WebMenuProcessor#save_menu_structure`

When creating `OcrMenuItem`, store `size_prices` in metadata:
```ruby
metadata = {}
if item_data[:size_prices].is_a?(Hash) && item_data[:size_prices].values.any?(&:present?)
  metadata['size_prices'] = item_data[:size_prices].transform_values { |v| v&.to_f }
end
```

#### 3.2.3 Update `PdfMenuProcessor` similarly
Apply the same GPT prompt changes and metadata storage to `PdfMenuProcessor` for PDF wine list imports.

#### 3.2.4 Update price inference pass
In `infer_missing_prices`, skip size-priced items (they already have structured pricing). For items with `size_prices` but missing some sizes, optionally infer missing size prices from ratios of other wines in the same section.

---

### Phase W-P3: Import Confirm — Create Size Mappings
**Goal:** When OCR import is confirmed, create `MenuitemSizeMapping` records for wine items.

#### 3.3.1 Update `ImportToMenu#build_sections_and_items!`

After creating a `Menuitem` with `itemtype: :wine`:
```ruby
if menuitem.wine? && item.metadata&.dig('size_prices').present?
  WineSizeSeeder.seed!(restaurant) # ensure wine sizes exist
  size_prices = item.metadata['size_prices']

  size_prices.each do |size_key, price_value|
    next if price_value.blank? || price_value.to_f <= 0

    wine_size = restaurant.sizes.wine.find_by(name: WINE_SIZE_NAMES[size_key])
    next unless wine_size

    menuitem.menuitem_size_mappings.find_or_create_by!(size: wine_size) do |mapping|
      mapping.price = price_value.to_f
    end
  end

  # Set the default price to bottle, or the first available size
  bottle_price = size_prices['bottle']&.to_f
  if bottle_price && bottle_price > 0
    menuitem.update!(price: bottle_price)
  end
end
```

#### 3.3.2 Define `WINE_SIZE_NAMES` mapping
```ruby
WINE_SIZE_NAMES = {
  'bottle' => 'Bottle (750ml)',
  'glass' => 'Glass (175ml)',
  'large_glass' => 'Large Glass (250ml)',
  'half_bottle' => 'Half Bottle (375ml)',
  'carafe' => 'Carafe (500ml)',
}.freeze
```

---

### Phase W-P4: Customer Ordering UX
**Goal:** Wine items show a prominent, elegant size selector instead of hidden dropdown.

#### 3.4.1 New partial: `_showMenuitemWineSizes.erb`

For wine items with size mappings, render an inline pill/chip selector:
```
┌──────────────────────────────────────────────┐
│  Château Margaux 2015                        │
│  Bordeaux, Cabernet Sauvignon blend          │
│                                              │
│  ┌─────────┐ ┌───────┐ ┌─────────────┐      │
│  │ Glass   │ │ Large │ │   Bottle    │  [+]  │
│  │  €18    │ │  €24  │ │    €180     │       │
│  └─────────┘ └───────┘ └─────────────┘       │
└──────────────────────────────────────────────┘
```

- Pills are styled buttons; tapping one selects the size
- Selected pill is highlighted (filled); others are outlined
- The [+] add-to-order button uses the currently selected size's price
- Default selection: **glass** (most common wine-bar order)
- On mobile: pills stack horizontally with horizontal scroll if needed

#### 3.4.2 Update `_showMenuitemHorizontalActionBar.erb`

Add conditional rendering:
```erb
<% if mi.wine? && mi.has_wine_sizes? %>
  <%= render partial: 'smartmenus/showMenuitemWineSizes',
       locals: { mi: mi, order: order, tablesetting: tablesetting,
                 restaurantCurrency: restaurantCurrency,
                 ordrparticipant: ordrparticipant,
                 menuparticipant: menuparticipant } %>
<% else %>
  <%# existing size dropdown / single price button %>
<% end %>
```

#### 3.4.3 JavaScript: Wine size selection

In `ordrs.js`, handle wine size pill selection:
- Clicking a size pill updates a `data-selected-size-name` and `data-selected-size-price` on the card
- The [+] button reads these attributes when opening the add-to-order modal
- Pass `size_name` through to the order creation payload

#### 3.4.4 Update add-to-order modal

Add a subtle size indicator below the item name when a size is selected:
```
Château Margaux 2015
Glass (175ml) · €18.00
```

#### 3.4.5 Staff view (`_showMenuitemStaff.erb`)

Extend the existing size dropdown for staff view to show wine sizes with prices prominently.

---

### Phase W-P5: Order Tracking
**Goal:** Record which size was ordered; display in order views and receipts.

#### 3.5.1 Update `ordritems_controller#create` and `OrderEventProjector`

Accept `size_name` in the order item payload:
```ruby
# ordritems_controller.rb
def ordritem_params
  params.require(:ordritem).permit(:ordr_id, :menuitem_id, :status, :ordritemprice, :size_name)
end
```

```ruby
# OrderEventProjector — item_added event
Ordritem.create!(
  ordr: ordr,
  menuitem_id: menuitem_id,
  ordritemprice: ordritemprice || 0.0,
  status: :opened,
  line_key: line_key.to_s,
  size_name: event.payload['size_name'] || event.payload[:size_name],
)
```

#### 3.5.2 Update JavaScript order posting

In the add-to-order click handler, include `size_name`:
```javascript
const ordritem = {
  ordritem: {
    ordr_id: ordrId,
    menuitem_id: menuitemId,
    status: ORDRITEM_ADDED,
    ordritemprice: price,
    size_name: sizeName || null,  // e.g. "Glass (175ml)"
  },
};
```

#### 3.5.3 Display in order views

Show size name alongside item name in:
- Customer order summary
- Staff order ticket
- Kitchen display
- Receipt/bill

Format: `Château Margaux 2015 — Glass (175ml)`

---

### Phase W-P6: Admin & Review UX
**Goal:** Staff can view and edit wine size prices in the admin interface.

#### 3.6.1 Menuitem edit form

For wine items, show a size-price table in the menuitem edit form:
```
Size                | Price
--------------------|--------
Bottle (750ml)      | €180.00
Glass (175ml)       | €18.00
Large Glass (250ml) | €24.00
```

Each row is editable. Staff can add/remove sizes.

#### 3.6.2 OCR review queue

In the OCR review/confirm view, show extracted `size_prices` for wine items so staff can verify/edit before confirming import.

---

## 4. File Change Summary

### New files
| File | Purpose |
|------|---------|
| `db/migrate/TIMESTAMP_add_wine_size_support.rb` | Add `category` to sizes, `size_name` to ordritems |
| `app/services/wine_size_seeder.rb` | Create canonical wine Size records for a restaurant |
| `app/views/smartmenus/_showMenuitemWineSizes.erb` | Customer-facing wine size pill selector |
| `test/services/wine_size_seeder_test.rb` | Unit tests |
| `test/services/import_to_menu_wine_sizes_test.rb` | Import pipeline tests |

### Modified files
| File | Change |
|------|--------|
| `app/models/size.rb` | Add `category` enum, `wine` scope |
| `app/models/menuitem.rb` | Add `wine_size_mappings`, `has_wine_sizes?` helpers |
| `app/models/ordritem.rb` | Document `size_name` column |
| `app/services/web_menu_processor.rb` | Update GPT prompt for wine multi-pricing |
| `app/services/pdf_menu_processor.rb` | Same GPT prompt update |
| `app/services/import_to_menu.rb` | Create `MenuitemSizeMapping` for wine items on confirm |
| `app/views/smartmenus/_showMenuitemHorizontalActionBar.erb` | Conditional wine size rendering |
| `app/views/smartmenus/_showMenuitemStaff.erb` | Wine size display for staff |
| `app/javascript/ordrs.js` | Wine size pill selection + pass `size_name` in order payload |
| `app/controllers/ordritems_controller.rb` | Permit `size_name` param |
| `app/services/order_event_projector.rb` | Store `size_name` on Ordritem |

---

## 5. Edge Cases & Guardrails

1. **Wine with only one size** — render as normal item (no pill selector)
2. **Wine with no prices** — show sizes without prices; order button disabled until staff adds prices
3. **Non-wine items with sizes** — continue using existing dropdown (no regression)
4. **Size deleted after order placed** — `size_name` is a string on ordritem, so historical orders are unaffected
5. **Import of non-wine-bar restaurant** — `size_prices` is optional in GPT output; ignored for non-wine items
6. **Currency** — all prices follow the restaurant's existing currency setting
7. **Localisation** — size names are stored in English; can be extended with I18n keys later
8. **Tasting menu wines** — tasting menu flow is unaffected; wine sizes are for à-la-carte ordering only

---

## 6. Testing Strategy

| Test | Scope |
|------|-------|
| `WineSizeSeeder` creates correct sizes for restaurant | Unit |
| GPT prompt extracts `size_prices` for wine items | Service (mock OpenAI) |
| `OcrMenuItem.metadata['size_prices']` is populated during import | Service |
| `ImportToMenu` creates `MenuitemSizeMapping` for wine items | Service |
| `ImportToMenu` sets bottle price as default `Menuitem.price` | Service |
| `Ordritem` stores `size_name` when wine size is ordered | Model |
| `OrderEventProjector` propagates `size_name` to Ordritem | Service |
| Customer view shows wine size pills for wine items | System/view |
| Customer view shows regular dropdown for non-wine sized items | System/view |
| Order summary displays size name | View |

---

## 7. Out of Scope (Future)

- **Vintage tracking** as a first-class field (currently in description)
- **Wine pairing recommendations** (separate feature)
- **Split-size pricing rules** (e.g. "glass = bottle ÷ 5") — manual for now
- **I18n for size names** (English-only initially)
- **Sommelier integration** for wine-by-the-glass recommendations
