---
name: Api::V1::OrdersController create/show references non-existent Ordritem columns
description: OrdersController#create writes unit_price, total_price, special_instructions on Ordritem and reads them back in order_with_items_json — none of these columns exist on the ordritems table
type: project
---

`Api::V1::OrdersController#create` (lines 56–63) calls `@order.ordritems.create!` with:
- `unit_price: menu_item.price`
- `total_price: menu_item.price * item_params[:quantity].to_i`
- `special_instructions: item_params[:special_instructions]`

`order_with_items_json` (lines 134–147) reads back `item.unit_price`, `item.total_price`, `item.special_instructions`.

None of these columns exist on the `ordritems` table (confirmed in db/schema.rb lines 995–1018). The create! call will raise `ActiveRecord::UnknownAttributeError` for any POST to `/api/v1/restaurants/:id/orders` that includes items. The show serialisation will return `nil` for all three fields.

**Why:** Fields from a different model design were referenced without a migration.

**How to apply:** The correct Ordritem column for price is `ordritemprice`. There is no `total_price` or `special_instructions` column — notes go through `Ordritemnote`. The fix requires either adding the columns or rewriting create to use the correct attributes.
