---
name: StripeIngestor handle_account_updated nil-check bug on boolean fields
description: handle_account_updated uses !obj['field'].nil? to test boolean Stripe fields — evaluates to true even when field is false, causing ProviderAccount to always be set to :enabled
type: project
---

In `app/services/payments/webhooks/stripe_ingestor.rb`, the `handle_account_updated` method (around line 252) reads:

```ruby
charges_enabled = !obj['charges_enabled'].nil?
payouts_enabled = !obj['payouts_enabled'].nil?
details_submitted = !obj['details_submitted'].nil?
```

Stripe sends these as booleans (`false` or `true`). `false.nil?` returns `false`, so `!false.nil?` is `true`. This means when Stripe reports `charges_enabled: false`, the code sets `charges_enabled = true` — the exact opposite of reality.

**Why:** Confusing nil-check (presence guard) with truthiness check on boolean fields.

**How to apply:** The fix is `charges_enabled = obj['charges_enabled'] == true` (or `!!obj['charges_enabled']`). The same pattern should be audited anywhere Stripe boolean fields are accessed via nil-check.
