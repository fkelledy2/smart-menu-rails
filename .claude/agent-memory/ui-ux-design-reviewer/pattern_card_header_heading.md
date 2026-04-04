---
name: Card header heading pattern
description: Correct pattern for card headers is fw-semibold text directly in .card-header, not nested h5/h6 with card-title class
type: project
---

The correct Bootstrap 5 pattern for card headers in this codebase is:

```html
<div class="card-header fw-semibold">Section Title</div>
```

Not:
```html
<div class="card-header"><h5 class="card-title">Section Title</h5></div>
```

The `card-title` class belongs in `card-body`, not in `card-header`. Multiple admin views had this wrong pattern.

**Why:** Semantic correctness, consistent visual weight, avoids extra heading nesting that breaks document outline.

**How to apply:** Any time a `card-header` contains only a title, use `fw-semibold` on the div itself. If the header has an icon prefix, use `<span class="fw-semibold"><i ...></i> Title</span>`.
