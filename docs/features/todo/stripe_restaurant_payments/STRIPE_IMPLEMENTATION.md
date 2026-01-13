# Stripe Implementation: Restaurant SaaS Billing

## Scope
Implement Stripe-based SaaS billing for restaurants, governed by the selected `Plan`.

This is **not** the existing customer-order checkout flow (`Payments::IntentsController` / `Payments::BaseController`).

## Stripe Objects
- **Product**: Mellow Menu subscription product (typically one product)
- **Price**: one per plan and billing interval (monthly/yearly)
- **Customer**: represents the restaurant account owner (or the restaurant entity)
- **Subscription**: the recurring SaaS agreement
- **Checkout Session (subscription mode)**: recommended UI to collect payment details + start subscription

## Recommended Approach
### Use Stripe Checkout for subscriptions
- Use `Stripe::Checkout::Session.create` with `mode: 'subscription'`.
- Set `line_items` to the `Price` corresponding to the selected `Plan`.
- Let Checkout collect payment method and handle SCA.

Why:
- Fastest to ship
- Lowest PCI burden
- Built-in support for taxes, invoices, coupons, etc.

## Data Model (Proposed)
We need to persist identifiers and subscription state.

### Option 1 (Recommended): `RestaurantSubscription` model
Create a new model linked to `Restaurant`:
- `restaurant_id`
- `stripe_customer_id`
- `stripe_subscription_id`
- `stripe_price_id`
- `status` (trialing/active/past_due/canceled/incomplete)
- `current_period_end`
- timestamps

Pros:
- Supports multiple restaurants per user
- Clear “subscription per restaurant” boundary

### Option 2: Store on `User`
Store SaaS billing directly on `User`.

Pros:
- simpler

Cons:
- ambiguous when user owns multiple restaurants

## Plan ↔ Stripe Price mapping
`Plan` currently has:
- `key`
- `pricePerMonth`, `pricePerYear`

Add (recommended):
- `stripe_price_id_monthly`
- `stripe_price_id_yearly`

This keeps Stripe as the source of truth for billing calculations.

## Onboarding Integration
Add a new onboarding step (Step 3.5) as described in `ONBOARDING_PLACEMENT.md`.

### Flow
1. User selects a plan (existing Step 3)
2. App creates/reuses Stripe Customer
3. App creates Stripe Checkout Session (subscription)
4. User completes payment in Stripe-hosted page
5. Stripe redirects to success URL
6. Webhook confirms subscription and updates local DB
7. User continues onboarding to menu creation

## Controllers / Routes (Proposed)
- `Billing::CheckoutSessionsController#create`
  - Creates checkout session for current restaurant + selected plan
- `Billing::CheckoutSessionsController#success`
  - Displays success and advances onboarding
- `Billing::CheckoutSessionsController#cancel`
  - Displays cancel state and offers retry
- `Billing::WebhooksController#create`
  - Receives Stripe webhook events

Webhook route should be unauthenticated but signature-verified.

## Webhooks (Required)
Implement signature verification using Stripe webhook signing secret.

Minimum events:
- `checkout.session.completed`
- `customer.subscription.created`
- `customer.subscription.updated`
- `customer.subscription.deleted`
- `invoice.payment_succeeded`
- `invoice.payment_failed`

### Idempotency
- Use `event.id` stored in a `stripe_events` table (or similar) to ensure each webhook is processed once.

## Authorization
Only restaurant owners/admins should:
- initiate billing checkout
- view billing status
- change plan
- cancel subscription

## Subscription State Handling
- If subscription becomes `past_due` or `unpaid`, enforce gating:
  - disable paid features
  - show a banner prompting to update payment method
- Provide a “Manage billing” link using the Stripe Customer Portal.

## Stripe Customer Portal (Recommended)
Offer a Customer Portal session so users can:
- update payment method
- download invoices
- cancel subscription

## Migration / Rollout Plan
1. Add DB tables/columns for subscription identifiers and status.
2. Implement checkout session creation + onboarding step.
3. Implement webhooks + idempotency.
4. Add UI surfaces:
   - onboarding payment step
   - settings page “Billing”
5. Backfill: existing users can be prompted to add billing later.

## Testing
- Request specs for checkout session creation
- Webhook specs using Stripe signature fixtures
- System test for onboarding step progression (happy path + cancel)
