---
name: API V1 OrdersController uses non-existent Ordr fields
description: Api::V1::OrdersController references columns and methods that don't exist on the Ordr model or ordrs table
type: project
---

`app/controllers/api/v1/orders_controller.rb` was written against a different schema than `Ordr` / the `ordrs` table. Specifically:

- `order_params` permits `:table_number, :customer_name, :customer_phone, :notes` — none of these columns exist on `ordrs`
- `order_json` calls `order.subtotal`, `order.service_charge`, `order.total` — `ordrs` has `nett`, `service`, `tax`, `gross` but not `subtotal`, `service_charge`, or `total`
- `@order.calculate_totals!` is called after creating order items — this method does not exist on `Ordr`, raising `NoMethodError`
- `@restaurant.ordrs.build(order_params)` will always fail save because `tablesetting_id` and `menu_id` are `null: false` and not included in the permitted params

The `create` action will raise `NoMethodError` on the `calculate_totals!` call for any request that includes items. The `subtotal`/`service_charge`/`total` references silently return nil, defaulting to 0 in the JSON response.

**Why:** This controller was built generically and doesn't match Smart Menu's non-standard order schema. The `ordrs` table uses `gross`, `nett`, `service`, `tax` (not standard ORM naming).

**How to apply:** The entire `Api::V1::OrdersController` needs to be rewritten to match the actual `Ordr` model and `ordrs` schema.
