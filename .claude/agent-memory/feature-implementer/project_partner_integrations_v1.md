---
name: Partner Integrations v1 implementation decisions
description: Partner Integrations #11 event-driven architecture, scope additions, adapter pattern, key gotchas (March 2026)
type: project
---

## Partner Integrations #11 — completed 2026-03-29

### Architecture decisions
- **CanonicalEvent** is a frozen value object — raises `ArgumentError` on bad event_type or blank restaurant_id
- **EventEmitter** guards with `Flipper.enabled?(:partner_integrations, restaurant)` AND checks `restaurant.enabled_integrations` jsonb array
- **Adapter dispatch** is fully async via `PartnerIntegrationDispatchJob` — never blocks request lifecycle
- **StripeIngestor** extended with `emit_partner_payment_event` private method called from `handle_payment_intent_succeeded`; errors are swallowed so partner dispatch never disrupts core order flow
- **NullAdapter** is the only registered adapter in v1 (string `'null'` — see gotcha below)

### New scopes added to AdminJwtToken::VALID_SCOPES
`workforce:read` and `crm:read` — these were missing and caused 401 in controller tests until added.

**Why:** `AdminJwtToken#scopes_are_valid` validates against the `VALID_SCOPES` constant; using an unrecognised scope causes token save to fail silently (returns `Result.new(success: false, ...)`), which means the token is never persisted, meaning the validator can never find it, causing 401.

**How to apply:** Whenever a new partner endpoint needs a scope, add it to `AdminJwtToken::VALID_SCOPES` first.

### YAML fixture gotcha
`adapter_type: null` in YAML is parsed as Ruby `nil`, not the string `"null"`.
**Fix:** Quote it as `adapter_type: 'null'`.

### Metrics/ParameterLists gotcha
`pluck(...7 columns...).map do |a, b, c, d, e, f, g|` triggers RuboCop's parameter list cop.
**Fix:** Extract to a named method (`build_pacing_entry(row)`) and destructure inside.

### Route params
The partner endpoints live at `/api/v1/restaurants/:restaurant_id/partner/...`
The URL param is `:restaurant_id`, NOT `:id`. Test paths must use `restaurant_id: 999` not `id: 999`.

### Flipper flag
`partner_integrations` — added to `config/initializers/flipper.rb`, disabled by default. Enable per-restaurant via Flipper UI once a partner is configured.

### Dead-letter logging
`record_dead_letter` is a private method called from `retry_on`'s failure block. Instance variables `@restaurant_id`, `@adapter_type`, `@event_payload` are set during `perform` so the dead-letter handler has context even after retry exhaustion.
