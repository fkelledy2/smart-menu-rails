---
name: button_to block element stacking pattern
description: button_to renders a <form> block element — without a flex wrapper, siblings stack vertically instead of sitting inline
type: project
---

`button_to` in Rails renders a `<form>` element which is `display: block` by default. When placed next to a `link_to` or another `button_to` without a flex wrapper, the form blocks break onto separate lines.

**Pattern to use in action cells:**
```erb
<td class="text-end">
  <div class="d-flex justify-content-end gap-1">
    <%= link_to 'Edit', edit_path, class: 'btn btn-outline-secondary btn-sm' %>
    <%= button_to 'Delete', path, method: :delete, class: 'btn btn-outline-danger btn-sm',
          form: { data: { turbo_confirm: '...' } } %>
  </div>
</td>
```

**When button_to is alone in a d-flex gap-N parent:**
Add `form: { class: 'd-flex' }` to make the form inline:
```erb
<div class="d-flex gap-2">
  <%= button_to 'Approve', path, method: :patch, class: 'btn btn-success',
        form: { class: 'd-flex' } %>
  <%= button_to 'Reject', path, method: :patch, class: 'btn btn-outline-danger',
        form: { class: 'd-flex' } %>
</div>
```

**For form_with submit + another form_with submit side by side:**
Add `class: 'd-flex'` (or `class: 'd-flex align-items-center gap-1'`) to the form_with call itself.

**Why:** Block-level `<form>` elements break inline button layouts. This is a very common gotcha in Rails 7 + Turbo views where `link_to method: :post` has been correctly replaced with `button_to`.

**How to apply:** Any time two actions need to appear inline in a table cell or action bar, wrap in `d-flex gap-1`. Check for `me-1` margin hacks on buttons — these are often a sign the flex wrapper is missing.

**Files fixed in April 2026 sweep:**
- admin/margin_policies/index.html.erb
- admin/pricing_models/index.html.erb
- admin/staff_costs/index.html.erb
- admin/discovered_restaurants/show.html.erb (Approve/Reject)
- restaurants/agent_workbench/show.html.erb (Approve/Reject per-approval)
- admin/whiskey_flights/new.html.erb + edit.html.erb (submit/cancel)
