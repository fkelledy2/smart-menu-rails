---
name: link_to with data-method is broken in Rails 7 + Turbo
description: link_to with data: { turbo_method: :post } renders as GET in Rails 7 + Turbo — must be button_to
type: project
---

In Rails 7 with Turbo, `link_to url, data: { turbo_method: :post }` does NOT reliably perform a POST. Turbo intercepts navigation and the `data-turbo-method` hint can be ignored depending on the Turbo version.

**Rule:** Any action that mutates data (POST, PATCH, DELETE) must use `button_to`, never `link_to` with a method hint.

**Wrong (Rails 6 pattern):**
```erb
<%= link_to 'Sync', resync_path, data: { turbo: true, turbo_method: :post } %>
```

**Correct (Rails 7 + Turbo):**
```erb
<%= button_to 'Sync', resync_path, method: :post,
      form: { class: 'd-flex' } %>
```

For icon-style inline links that need to POST (e.g. refresh buttons in the discovered restaurant detail page):
```erb
<%= button_to path, method: :post,
      class: 'btn btn-link p-0 text-decoration-none text-body',
      title: '...',
      form: { class: 'd-inline' } do %>
  <i class="bi bi-arrow-clockwise"></i>
<% end %>
```

**Why:** link_to renders as `<a>` — GET requests. data-turbo-method requires Turbo's UJS layer to intercept, which is unreliable. This was a P1 bug class (Bug 5 in the April 2026 bug fix commit).

**Files fixed in April 2026 sweep:**
- admin/discovered_restaurants/show.html.erb — refresh_place_details, deep_dive_website, scrape_web_menus, resync_to_restaurant all converted from link_to (data: turbo_method) to button_to
