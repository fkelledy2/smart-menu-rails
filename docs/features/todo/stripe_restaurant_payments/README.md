# Stripe Restaurant Payments (SaaS Billing)

## Goal
Collect payment details during onboarding to start a recurring SaaS subscription that bills the **restaurant account** for Mellow Menu services.

This is **separate** from existing Stripe usage in the app for **customer order payments** (`Payments::IntentsController` / `Payments::BaseController`).

## Current State (as of today)
- Stripe is used for **end-customer payments**:
  - `Stripe::PaymentIntent` creation for paying a specific `Ordr`
  - `Stripe::PaymentLink` creation for paying a specific `Ordr`
  - `Ordr` has `paymentlink` and `paymentstatus`
- Plans exist (`Plan`, `Userplan`) and onboarding includes plan selection, but there is **no Stripe subscription billing** for the SaaS fee yet.

## What this feature adds
- A Stripe Customer + Subscription for billing the SaaS fee.
- Billing is governed by the plan selected in onboarding (`User.plan`).
- A clear onboarding step for entering payment details.
- Webhook-driven lifecycle handling (payment success/failure, cancellations, plan changes).

## Documentation Index
- `ONBOARDING_PLACEMENT.md`
- `STRIPE_IMPLEMENTATION.md`
