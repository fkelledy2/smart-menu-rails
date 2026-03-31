---
name: ILIKE without sanitize_sql_like
description: LIKE/ILIKE queries embedding user input without sanitize_sql_like allow wildcard injection — % and _ have special meaning in LIKE patterns
type: feedback
---

`RestaurantsController#index` had `where('restaurants.name ILIKE ?', "%#{q}%")` and `Admin::DiscoveredRestaurantsController` had the same pattern for `city`. Parameterized queries prevent SQL injection but do NOT escape `%` and `_` within the LIKE pattern itself.

**Why it matters:** A user supplying `%` or `____` can match far more rows than intended, defeating search precision. In the worst case, `%` alone matches all rows — bypassing the search intent and potentially exposing all restaurant names to a search UI.

**Fix:** Wrap user input in `Model.sanitize_sql_like(input)` before embedding: `"%#{Restaurant.sanitize_sql_like(q)}%"`.

**Files fixed:**
- `app/controllers/restaurants_controller.rb:29`
- `app/controllers/admin/discovered_restaurants_controller.rb:23` and `:388`

**How to apply:** Any time user input is embedded in a LIKE/ILIKE pattern string, even inside parameterized `?` queries, call `sanitize_sql_like` first.
