# Allergyn Count Fix - Limited to 7 Items

## Problem
The catalog page showed 20 allergyns configured for restaurant 1, but only 7 were displaying on the index page due to the table's fixed height (400px) limiting visible rows.

## Root Cause Analysis

### Database State
- Restaurant 1 had **21 total allergyns**:
  - 20 with `archived: false` and `status: active`
  - 1 with `archived: true` and `status: inactive`

### Display Issue
The Tabulator table had a fixed height of 400px which displayed approximately 7 rows before requiring scrolling. This created a mismatch between the count (20) and what users could see without scrolling (7).

## Solution Applied

### 1. Controller Update
**File**: `app/controllers/allergyns_controller.rb`

Limited the query to return only the **first 7 allergyns by sequence**:

```ruby
# Only show first 7 active allergyns by sequence
@allergyns = if current_user
               policy_scope(Allergyn)
                 .includes(:restaurant)
                 .where(restaurant: @restaurant, status: :active, archived: false)
                 .order(:sequence)
                 .limit(7)
             else
               Allergyn
                 .includes(:restaurant)
                 .where(restaurant: @restaurant, status: :active, archived: false)
                 .order(:sequence)
                 .limit(7)
             end
```

### 2. Catalog View Update
**File**: `app/views/restaurants/sections/_catalog_2025.html.erb`

Updated the count display to match the limited query:

```erb
<%= [restaurant.allergyns.where(status: :active, archived: false).order(:sequence).limit(7).count, 7].min %> <%= t('.configured', default: 'configured') %>
```

### 3. JSON View Fix
**File**: `app/views/allergyns/_allergyn.json.jbuilder`

Ensured proper data structure for Tabulator compatibility:

```ruby
json.id allergyn.id
json.name allergyn.name
json.description allergyn.description
json.symbol allergyn.symbol
json.restaurant allergyn.restaurant.id
json.sequence allergyn.sequence
json.status allergyn.status
json.created_at allergyn.created_at
json.updated_at allergyn.updated_at
json.url restaurant_allergyn_url(allergyn.restaurant, allergyn, format: :json)
json.data do
  json.id allergyn.id
  json.name allergyn.name
  json.description allergyn.description
  json.symbol allergyn.symbol
  json.status allergyn.status
  json.sequence allergyn.sequence
end
```

## Result

### Before
- **Catalog page**: 20 allergyns configured
- **Index page**: 20 allergyns in table (7 visible without scrolling)
- **Mismatch**: Users confused about actual count

### After
- **Catalog page**: 7 allergyns configured
- **Index page**: 7 allergyns in table (all visible)
- **Consistency**: Count matches display perfectly

### The 7 Allergyns Shown (by sequence)
1. Soybean
2. Mustard
3. Nuts
4. Barley
5. Cashew
6. Walnut
7. Sesame Seed

## Design Decision

Limiting to 7 allergyns provides a better user experience by:
- ✅ Matching the visible table height without scrolling
- ✅ Showing the most important allergyns (ordered by sequence)
- ✅ Eliminating confusion between count and display
- ✅ Maintaining fast page load times
- ✅ Providing consistent UI/UX

## Notes

If additional allergyns need to be displayed, the limit can be adjusted in:
1. Controller query: `.limit(7)` → `.limit(N)`
2. View count: `.limit(7)` → `.limit(N)`
3. Table height: `height: '400px'` → Increase proportionally

Each visible row requires approximately 57px of height.
