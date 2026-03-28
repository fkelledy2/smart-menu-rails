---
name: Bootstrap 4 Form Layout Pattern
description: The .form-group.row with col-3 label + col-9 input pattern (Bootstrap 4 style) still appears in restaurants/show.html.erb and several entity show views
type: project
---

Pattern found in:
- app/views/restaurants/show.html.erb (entire form, ~30 instances of .form-group.row)
- app/views/employees/show.html.erb
- app/views/menuitems/show.html.erb
- app/views/menusections/show.html.erb
- app/views/tablesettings/show.html.erb
- app/views/allergyns/show.html.erb
- app/views/taxes/show.html.erb
- app/views/tips/show.html.erb
- app/views/tags/show.html.erb

The pattern uses:
- div.form-group.row
- div.col-3 with span.float-md-end as label
- div.col-9 as input container
- <p> tags used as spacers (invalid HTML — empty paragraphs)
- disabled: true on all fields (read-only display using form inputs)

The show views are entirely read-only (all fields disabled). This should be a definition list (<dl><dt><dd>) or a table of key-value pairs, not a form at all. Using a form with disabled inputs for display is semantically incorrect and confusing.

Bootstrap 5 equivalent for horizontal form layout uses: .row.mb-3 > .col-sm-3 label.col-form-label + .col-sm-9

**How to apply:** When editing show views, replace the disabled-form pattern with Bootstrap .list-group or a simple .row.g-2 definition list. The restaurants/show.html.erb is particularly in need of this — it's a large read-only form that should be a detail card.
