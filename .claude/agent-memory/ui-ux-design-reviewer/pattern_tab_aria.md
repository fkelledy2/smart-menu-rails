---
name: Tab accessibility attributes pattern
description: Bootstrap 5 tabs need aria-controls, aria-selected on tab triggers and aria-labelledby on tab panels — several admin views were missing these
type: project
---

Bootstrap 5 tabs require the following ARIA attributes for accessibility:

**Tab triggers (buttons or links):**
- `role="tab"` on the `<li>` or trigger element  
- `aria-controls="panel-id"` pointing to the panel
- `aria-selected="true/false"`

**Tab panels:**
- `role="tabpanel"`
- `aria-labelledby="tab-id"` pointing back to the trigger

**Example (button tabs):**
```html
<button class="nav-link active" id="overview-tab" data-bs-toggle="tab" data-bs-target="#overview"
        type="button" role="tab" aria-controls="overview" aria-selected="true">
  Overview
</button>
...
<div class="tab-pane fade show active" id="overview" role="tabpanel" aria-labelledby="overview-tab">
```

**Example (link tabs):**
```html
<a class="nav-link active" href="#notes" data-bs-toggle="tab" role="tab" aria-controls="notes" aria-selected="true">
  Notes
</a>
```

**Why:** WCAG 2.1 AA compliance. Screen readers need these to announce tab count and selected state.

**How to apply:** Any time tabs are added to admin views, include all four attributes. Check performance/index.html.erb and crm/leads/show.html.erb as reference implementations.
