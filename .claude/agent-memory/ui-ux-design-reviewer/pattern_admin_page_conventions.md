---
name: Admin page layout conventions
description: Verified Bootstrap/HTML conventions used consistently across all well-styled admin views (demo_bookings, restaurant_removal_requests, restaurant_claim_requests, crm/leads)
type: project
---

These conventions were confirmed by reading 5+ admin views. Apply them to any admin page rewrite or new admin view.

## Outer wrapper
`<div class="container-fluid py-3">` — always `py-3`, never `py-4`. No `px-0`.

## Page title
- Always set `<% content_for :title, 'Page Name — Admin' %>` at the top.
- Title heading: `h1` with class `h4 mb-0` (not `h1 text-2xl fw-semibold`).

## Header row
```erb
<div class="d-flex align-items-center justify-content-between mb-3">
  <div>
    <h1 class="h4 mb-1">Page Title</h1>
    <p class="text-muted mb-0 small">Subtitle or count.</p>
  </div>
  <div class="d-flex gap-2">
    <%# CTAs and filter tabs here %>
  </div>
</div>
```

## Status filter tabs (in header right column)
```erb
<%= link_to 'All', path, class: "btn btn-sm #{@status.blank? ? 'btn-primary' : 'btn-outline-secondary'}" %>
<% Model.statuses.keys.each do |s| %>
  <%= link_to s.humanize, path(status: s), class: "btn btn-sm #{@status == s ? 'btn-primary' : 'btn-outline-secondary'}" %>
<% end %>
```

## Empty state
`<div class="alert alert-info">No records found.</div>` — not a custom icon component.

## Table
`<table class="table table-sm align-middle">` with a plain `<thead>` (no `table-light` class on thead by default).
Use `table-hover` when rows are clickable.

## Status badges
- Pending/warning: `badge bg-warning text-dark`
- Approved/success: `badge bg-success`
- Rejected/neutral: `badge bg-secondary`
- Info/processing: `badge bg-info text-dark`

## Back navigation on show pages
```erb
<%= link_to parent_path, class: 'btn btn-sm btn-outline-secondary' do %>
  <i class="bi bi-arrow-left"></i> Back Label
<% end %>
```
Use `btn btn-sm btn-outline-secondary` not just a bare link.

## Cards on show pages
Section content lives in `.card > .card-body`. Section sub-headings: `h2 class="h6 fw-semibold mb-3"`.

## Form labels
`<label class="form-label small text-muted mb-1">` — small muted label above each input.

## Approve/Reject button pair
Primary action (`btn-success`) on left, destructive (`btn-outline-danger`) on right. Always `data: { turbo_confirm: '...' }` on destructive.

**Why:** Consistency audit across admin namespace — these patterns appear in restaurant_removal_requests, restaurant_claim_requests, demo_bookings, crm/leads, and discovered_restaurants after rewrite.

**How to apply:** Any time writing or reviewing an admin/* view, enforce all of the above before considering it aligned.
