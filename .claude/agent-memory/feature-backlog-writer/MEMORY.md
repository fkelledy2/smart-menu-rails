# Feature Backlog Writer — Memory Index

## Architecture Decisions
- [arch_crm_admin_only.md](arch_crm_admin_only.md) — CRM is admin-namespace only; no tenant scoping
- [arch_ordritem_fulfillment_status.md](arch_ordritem_fulfillment_status.md) — Ordritem has two separate enums: `status` (commercial lifecycle) and `fulfillment_status` (kitchen/bar tracking); never conflate them
- [arch_ordr_channel_customer_broadcast.md](arch_ordr_channel_customer_broadcast.md) — Customer realtime broadcasts use existing `ordr_#{id}_channel` via OrdrChannel; OrdrChannel has no auth guard (latent risk, tracked in #34 open questions)
- [arch_razorpay_adapter_pattern.md](arch_razorpay_adapter_pattern.md) — Razorpay via BaseAdapter extension; UPI is async (poller job); create_and_capture_intent! not supported for UPI
- [arch_india_table_mode.md](arch_india_table_mode.md) — Shared table sessions: group_token on DiningSession + table_group_id on Ordr; reuses Ordrparticipant for settlement
- [arch_gst_tax_inclusive.md](arch_gst_tax_inclusive.md) — GST config on Restaurant; MenuItem stores inclusive price; GstInvoiceBuilder for display breakdown

## Patterns
- [pattern_webhook_verification.md](pattern_webhook_verification.md) — Webhook verification service pattern used across CRM and Strikepay
- [pattern_audit_trail.md](pattern_audit_trail.md) — Dedicated audit model preferred over paper_trail gem for immutable field-change logs
- [pattern_kanban_drag_drop.md](pattern_kanban_drag_drop.md) — Sortable.js + Stimulus + Turbo Stream PATCH for Kanban drag-and-drop
- [pattern_theming_css_custom_properties.md](pattern_theming_css_custom_properties.md) — Theming via data-theme on html + CSS custom property overrides; extends dark-mode pattern

- [arch_invisible_captcha_installed.md](arch_invisible_captcha_installed.md) — invisible_captcha ~> 2.3 is in Gemfile + initializer but unwired to any controller/view as of 2026-04-04
- [arch_clearbit_deprecated.md](arch_clearbit_deprecated.md) — Clearbit deprecated post-HubSpot acquisition; use Hunter.io + HTTParty for email enrichment (httparty already in Gemfile)
- [arch_contact_form_simple.md](arch_contact_form_simple.md) — Contact model captures only email + message; no name/restaurant; contact→CRM ingestion is spec #27

## Deferred Scope
- [deferred_crm_v2.md](deferred_crm_v2.md) — Items consistently deferred from CRM v1 to v2
- [deferred_india_v2.md](deferred_india_v2.md) — Items deferred from India market expansion v1 (HSN/SAC, GSTIN API, regional languages, POS, delivery)
