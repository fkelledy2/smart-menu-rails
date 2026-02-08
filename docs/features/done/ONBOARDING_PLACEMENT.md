# Onboarding Placement: When to Collect Billing Details

## Context
Current onboarding steps are implemented in `OnboardingController`:
1. Account details (+ create restaurant name and redirect to restaurant edit)
2. Restaurant details
3. Plan selection
4. Menu creation
5. Completion

We want to set up **recurring SaaS billing** for Mellow Menu via Stripe, governed by the selected plan.

## Recommendation (Best Default)
Add a new onboarding step **after Plan Selection (Step 3)** and **before Menu Creation (Step 4)**:

- Step 3: Choose plan (already exists)
- **Step 3.5: Add payment method / start subscription (new)**
- Step 4: Create first menu (existing)

### Why this point is optimal
- **Plan-driven pricing is known**: we can accurately create a Stripe subscription for the chosen plan.
- **Highest conversion moment**: the user has just committed to a tier.
- **Reduces provisioning risk**: we avoid doing significant background provisioning (menus/images/jobs) for users who will never pay.
- **Clear mental model**: “Pick plan” -> “Pay for plan” -> “Set up menu”.

### Addressing the “after first menu” requirement
If you want users to feel value before payment, keep Step 3.5 but include:
- A **trial period** (e.g. 7–14 days) on the Stripe subscription, OR
- A “Skip for now” path that allows menu creation but gates **Go Live / QR publishing** until payment is added.

In both cases, payment is still captured early, but the user experience feels “try it first”.

## Alternative Placement Options

### Option A: After Menu Creation (between Steps 4 and 5)
**Pros**:
- User has built their first menu and feels value.
- Better for product-led growth.

**Cons**:
- You spend compute/time provisioning for non-paying users.
- More users complete onboarding without billing and then churn.

### Option B: Immediately after Restaurant Details (between Steps 2 and 3)
**Pros**:
- Earliest possible revenue capture.

**Cons**:
- Price/plan may not be selected yet.
- Higher drop-off because user hasn’t committed to a plan.

## Recommended Gating Rules
- Users can complete steps 1–3 without billing.
- Payment step is required before:
  - completing onboarding (Step 5), OR
  - generating “production” QR codes / enabling ordering, OR
  - enabling any paid-only features.

## Edge Cases
- **Plan changes during onboarding**: if user changes plan before payment, recompute price and recreate Checkout Session.
- **Multiple restaurants per user**: decide if subscription is per-user (account) or per-restaurant. This spec assumes per-restaurant, but can be adapted.
- **Team members**: only owners/admins should manage billing.
