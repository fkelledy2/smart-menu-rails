---
name: Refunds::Creator does not support Square provider
description: Payments::Refunds::Creator#provider_adapter raised ArgumentError for :square — Square refunds completely broken
type: feedback
---

`Payments::Refunds::Creator#provider_adapter` only handled `:stripe` and raised `ArgumentError` for any other provider including `:square`. Since `Payments::Providers::SquareAdapter` requires a `restaurant:` argument, the fix passes `payment_attempt:` as a keyword arg through to `provider_adapter` so it can construct `SquareAdapter.new(restaurant: payment_attempt.restaurant)`.

**Why:** Square support was added to the adapter but not wired into Creator.

**How to apply:** When adding a new payment provider adapter, always update Creator#provider_adapter at the same time.
