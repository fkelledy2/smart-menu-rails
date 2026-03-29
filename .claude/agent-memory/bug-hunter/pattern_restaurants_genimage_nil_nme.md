---
name: pattern_restaurants_genimage_nil_nme
description: RestaurantsController#create and #update built a local @genimage but then called @restaurant.genimage.updated_at= on nil — NoMethodError on every restaurant create/update
type: feedback
---

In `RestaurantsController#create` and `#update`, when `@restaurant.genimage.nil?`, the code assigned a new `Genimage` to the local `@genimage` variable but then called `@restaurant.genimage.updated_at = ...` — which is `nil.updated_at=` because the record was never saved and the association was not set.

**Why:** The original code mixed up `@genimage` (local variable) and `@restaurant.genimage` (association accessor). The intent was simply to create a Genimage for the restaurant if one doesn't exist.

**Fix:** Replaced the 4-line block with `Genimage.create(restaurant: @restaurant)` in both `create` and `update`.

**How to apply:** When reviewing controller Genimage creation patterns, verify that the create block doesn't access `@restaurant.genimage` immediately after building a local `Genimage.new` without saving it first.
