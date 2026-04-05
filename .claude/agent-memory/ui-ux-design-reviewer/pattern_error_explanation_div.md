---
name: id="error_explanation" bare div pattern in scaffold forms
description: Rails scaffold generates id="error_explanation" divs with raw h2 — should be Bootstrap alert alert-danger; swept 2026-04-04
type: project
---

Scaffold-generated `_form.html.erb` files use:
```erb
<div id="error_explanation">
  <h2><%= pluralize(metric.errors.count, "error") %> prohibited...</h2>
  <ul>...</ul>
</div>
```

This is the default Rails scaffold output — no Bootstrap styling, no ARIA role.

**Fixed 2026-04-04:** Converted in: metrics/_form, ordractions/_form, ordritemnotes/_form, ordrparticipants/_form, ordritems/_form, tracks/_form, smartmenus/_form, genimages/_form.

**Correct Bootstrap 5 pattern:**
```erb
<div class="alert alert-danger mb-3" role="alert">
  <div class="fw-semibold mb-1"><%= pluralize(count, 'error') %>...</div>
  <ul class="mb-0">...</ul>
</div>
```

**How to apply:** When creating or reviewing any `_form.html.erb`, always use Bootstrap alert for errors. The `id="error_explanation"` pattern is legacy Rails scaffold output — replace it.
