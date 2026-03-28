---
name: Stripe Connect onboarding invalid status enum value
description: StripeConnectController#return updates ProviderAccount to status :active which is not a valid enum value — breaks all Stripe Connect onboarding
type: project
---

`Payments::StripeConnectController#return` (app/controllers/payments/stripe_connect_controller.rb line ~55) calls `provider_account.update!(status: :active, ...)`. The `ProviderAccount` enum has no `:active` value — valid values are `created`, `onboarding`, `enabled`, `restricted`, `disabled`. Rails raises `ArgumentError` which is swallowed by a `rescue StandardError` block, so onboarding silently fails and the restaurant can never accept payments.

Fix: change `:active` to `:enabled`.

**Why:** The `:active` value simply does not exist in the enum. The rescue masks the error completely.

**How to apply:** When investigating Stripe Connect onboarding failures or ProviderAccount status bugs, check this controller first. Also check for stuck ProviderAccount records in `onboarding` status in production — may need a data fix for records where Stripe reports `charges_enabled: true`.
