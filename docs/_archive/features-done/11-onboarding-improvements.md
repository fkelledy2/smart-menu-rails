# 11 - Onboarding Improvements (2026)

## Objective
Reduce onboarding drop-off and increase conversion by:
- Minimizing mandatory manual setup steps.
- Auto-provisioning sensible defaults on restaurant creation.
- Re-ordering steps so the user gets to “value” faster.
- Introducing a clear Payments “Merchant of Record” (MOR) choice with correct Stripe KYC gating.
- Instrumenting the onboarding funnel (Segment) to measure step completion and drop-off.

## Current State (as implemented today)

### 1) Global onboarding redirect (new users)
`ApplicationController#redirect_to_onboarding_if_needed`:
- If `user_signed_in?` and not a Devise controller and not `OnboardingController`.
- Skips XHR and JSON.
- Skips redirect if `current_user.employees.exists?(status: :active)`.
- Redirects if `current_user.needs_onboarding?`.

`User#needs_onboarding?` is currently:
- `!onboarding_complete? && restaurants.empty?`

Implication:
- A newly signed-up user with no restaurants is pushed into the `/onboarding` wizard.

### 2) Wizard onboarding flow
`OnboardingController` implements a 5-step wizard stored in `OnboardingSession`:
- Step 1: `account_details`
- Step 2: `restaurant_details`
- Step 3: `plan_selection`
- Step 4: `menu_creation`
- Step 5: `completion`

Instrumentation already exists in `AnalyticsService`:
- `onboarding_started`
- `onboarding_step_completed`
- `onboarding_step_failed`
- `onboarding_completed`

Important behavior in Step 1 (`handle_account_details`):
- Requires `restaurant_name`.
- Finds or creates a `Restaurant` for the user.
- If a new restaurant is created, it provisions an `Employee` record for `current_user` as a `manager`.
- Redirects to `edit_restaurant_path(restaurant)`.

Important behavior in Step 4:
- Enqueues `RestaurantOnboardingJob` which creates restaurant/menu data and default settings.

### 3) Restaurant edit “guided onboarding” (new OR existing users creating a restaurant)
`Restaurant#onboarding_next_section` enforces a required sequence when the user visits `RestaurantsController#edit`:

- **Details** required:
  - `description` present
  - `currency` present
  - at least one of `address1/city/postcode/country` present

- **Tables** required:
  - at least one `tablesettings`

- **Taxes and Tips** required:
  - at least one `tax` AND at least one `tip`

- **Localization** required:
  - at least one `restaurantlocale`
  - at least one default locale (`dfault: true`) among active locales

`RestaurantsController#edit` forces the user onto `onboarding_next_section` if they try to visit a different section.

### 4) Existing “default provisioning” behavior
There is already provisioning logic in `RestaurantOnboardingJob#create_default_restaurant_settings`:
- Creates default `tablesettings` (Table 1)
- Creates default `tax` (10%)
- Creates default `tip` (10%)
- Creates default locales (EN default + IT)
- Creates default restaurant opening times
- Creates demo allergens and sizes

However, this provisioning is tied to the wizard job path, not guaranteed for *all* restaurant creation paths.

### 5) Payments / MOR current behavior
`Payments::PaymentProfilesController#update`:
- Requires an enabled Stripe ProviderAccount before allowing `merchant_model` changes.
- Sets/updates `PaymentProfile#merchant_model`.

`Payments::FundsFlowRouter` currently switches charge behavior by `merchant_model`:
- `:smartmenu_mor` => `:destination`
- else `:direct`

### 6) Subscription billing readiness (missing)
We currently do **not** have a clear, enforced path that ensures a new restaurant owner/manager:
- Can pick a paid `mellow.menu` plan.
- Can start a recurring SaaS subscription.
- Has completed the minimum required Stripe onboarding steps to facilitate that subscription.

This document extends the plan to introduce a Stripe KYC/bank-details requirement in a way that:
- Minimizes early drop-off.
- Prevents “free value” beyond a defined trial/preview boundary.
- Keeps Merchant of Record (MoR) logic correct.

## Problems / Drop-off Drivers
- Too many mandatory steps before users get value.
- Guided onboarding gates navigation to a single next section; this can feel restrictive.
- Restaurant creation paths are inconsistent:
  - Wizard path provisions defaults (via job).
  - Standard `RestaurantsController#create` does not appear to provision defaults.
- Payments/MOR choice is not placed early enough in the journey to avoid later rework.
- Funnel measurement exists for the wizard, but not for restaurant edit gating (where drop-off likely happens).

Additional (current) problems:
- There is no explicit *paid conversion moment* that is enforced before “real usage”.
- There is no clear gating strategy for:
  - selecting a paid plan
  - starting a recurring subscription
  - enabling publishing/ordering

## Proposed Improvements

### A) Unify provisioning: always create sensible defaults on restaurant creation
Whenever a restaurant is created (regardless of entrypoint):
- **Create a default tip** (sample): 10% (or locale-specific suggestion).
- **Create a default tax** (sample): inferred by country/region when possible.
- **Create default locale**:
  - infer from restaurant country/address when possible
  - otherwise fall back to browser/user locale
  - ensure exactly one default active locale
- **Add current user as manager employee** (if missing) with `status: active`.

Goal:
- Make `Restaurant#onboarding_next_section` pass “Taxes and Tips” and “Localization” automatically, so the user is not forced through those sections immediately.

### B) Make onboarding less “blocking” and more “guided”
Instead of hard redirecting on every non-next section access:
- Allow navigation, but show a persistent banner:
  - “You’re X% set up. Recommended next: <section>.”
  - CTA button goes to the recommended step.

Keep hard-gating only for actions that truly cannot work without setup (e.g., enabling ordering or publishing menus).

### C) Re-order to “value-first” sequence
Recommended onboarding sequence for a new restaurant:
1. **Create restaurant** (minimal fields)
2. **Auto-provision defaults** (tip/tax/language/manager)
3. **Menu import/creation** (fastest route to value)
4. **Tables** (needed for capacity + in-venue operations, but not necessary for seeing the product)
5. **Payments (MOR + Stripe KYC)** (timed based on whether they want ordering enabled)

Rationale:
- Users get to a working menu and can view a Smart Menu/QR sooner.

### D) MOR choice and Stripe KYC gate
On restaurant creation (or first time entering Ordering/Payments settings), prompt:
- “Who should be Merchant of Record?”
  - Option 1: **MellowMenu as MOR** (`merchant_model: smartmenu_mor`)
  - Option 2: **Restaurant as MOR** (`merchant_model: restaurant_mor`)

Rules:
- If user selects **Restaurant as MOR**:
  - Stripe Connect onboarding / KYC must be completed (non-negotiable).
  - Ordering/Payments activation remains blocked until `ProviderAccount(status: enabled)`.

UX suggestion:
- Make this a single decision card with plain language explaining:
  - fees, payouts, responsibility for refunds/chargebacks, compliance.

### E) Subscription billing gate (Stripe bank details) for paid plans
We need a *separate* (but related) gate for **SaaS subscription billing**.

Key principle:
- **MoR selection is about customer payments** (if/when the restaurant accepts payments from patrons).
- **Bank details / Stripe KYC is also needed for paid subscription collection** (charging the restaurant for the SaaS plan), depending on the chosen billing architecture.

We should decide which of these billing architectures we are using:

Option E1 (recommended if we can): “Platform bills restaurant without restaurant Connect onboarding”
- The platform (mellow.menu) charges the restaurant as a customer for the SaaS subscription.
- The restaurant does **not** need Stripe Connect/bank details to pay a subscription.
- Benefits:
  - lowest onboarding friction
  - simplest conversion funnel
- Open question:
  - can we legally/operationally do this in our target regions, and does it fit our Stripe setup?

Option E2: “Restaurant must complete Stripe Connect (bank details) before paid plan starts”
- Paid plan selection triggers a requirement for Stripe Connect onboarding.
- Benefits:
  - aligns with having a connected account on file early
  - unifies payments compliance flows
- Cost:
  - higher drop-off

Decision (2026-01): we are proceeding with **Option E1**.

#### Proposed product gating rule (Option E1)
- User can set up and preview a Smart Menu without paying.
- User cannot obtain “real-world value” for free until they start a trial with card/bank details up-front.

Decision (2026-01): **Publish gate**
- Publishing / making the menu publicly usable by patrons is blocked until subscription is activated.

Decision (2026-01): **Trial with card/bank up-front**
- The trial can start immediately once payment method is on file.
- If a payment method is not on file:
  - allow preview
  - block publish

#### Recommended placement in the funnel
We should treat Stripe bank-details onboarding as a **late gate** at the moment of intent, not an early gate.

Recommendation:
1. Let the user:
  - create restaurant
  - create/import a menu
  - create a table / QR
  - preview Smart Menu internally
2. When they try to do one of:
  - publish / activate (customer-facing)
then require:
  - starting trial/subscription with payment method (Option E1)
  - (separately) explicit MoR selection
  - (separately) Stripe Connect onboarding only if MoR == restaurant_mor

This is a “value-first but not free” model.

#### How to prevent “free value”
Define a clear boundary between preview and real usage.

Candidate hard gates (choose the one we want as the activation boundary):
- Gate G1 (recommended): **Publishing**
  - allow preview on a private URL (or with a watermark)
  - block making it usable by patrons (publicly accessible)
- Gate G2: **QR export / printing**
  - allow preview QR but block downloading/printing/exporting high-res assets
- Gate G3: **Ordering / payments**
  - allow menu browsing for free, charge only when ordering is enabled

Decision (2026-01): we are using **G1 Publish gate**.

## Funnel Instrumentation Plan (Segment)

### Principles
- Use one consistent event namespace and include:
  - `restaurant_id`
  - `source` (signup_wizard, restaurants_new, clone_restaurant, etc.)
  - `step_name`
  - `required` (boolean)
  - `time_since_restaurant_created_seconds`

### Events to add
Wizard already emits step completion/failure. Add parallel events for restaurant setup onboarding:

1. `restaurant_onboarding_started`
- When a new restaurant is created OR when a user first lands on `edit_restaurant` for a restaurant that is `onboarding_incomplete?`.

2. `restaurant_onboarding_recommended_step_viewed`
- When the UI shows “Recommended next step: X” banner.

3. `restaurant_onboarding_step_viewed`
- When user views a section while in onboarding mode.
- Properties: `section`, `is_recommended`, `next_recommended_section`.

4. `restaurant_onboarding_step_completed`
- Fired when a section transitions from incomplete -> complete.
- Example transitions:
  - details_ok becomes true
  - tables count goes from 0 -> 1
  - taxes and tips both become present
  - locales present + default locale present

5. `restaurant_onboarding_abandoned`
- Fired if no completion events occur for N hours/days after `restaurant_onboarding_started`.
- Implementation approach:
  - Background job that checks “started but not completed” sessions.

6. `merchant_model_selected`
- Fired when user chooses MOR.
- Properties: `merchant_model`, `restaurant_id`, `stripe_status`.

7. `stripe_kyc_started` / `stripe_kyc_completed` / `stripe_kyc_failed`
- Fired around Stripe Connect onboarding lifecycle.

### Where to implement instrumentation
- Controller-level (server-side, reliable):
  - restaurant create
  - payments profile update
  - restaurant edit gating/recommendation
- Model/service-level for “completion transitions”:
  - compute previous/next `onboarding_next_section` and emit when it advances

## Implementation Touchpoints (likely)
- Restaurant creation:
  - `RestaurantsController#create` and/or a service object to provision defaults.
- Restaurant edit guidance:
  - `RestaurantsController#edit` currently hard-redirects; adjust to recommendation model.
- Defaults/inference:
  - a provisioning service, e.g. `RestaurantProvisioningService`.
  - tax inference can use `Restaurant#country` (or address parsing) with a mapping table.
- Payments:
  - `PaymentProfile`, `ProviderAccount`, `Payments::PaymentProfilesController`.
  - Ensure MOR choice is stored per restaurant and enforced before ordering activation.
- Analytics:
  - Add new `AnalyticsService` helpers for restaurant onboarding events.

## Open Questions
- Should we maintain both onboarding systems, or consolidate into one?
  - Recommendation: keep the signup wizard minimal, but move restaurant setup tracking into restaurant edit onboarding.
- What is the minimum “activation moment” that correlates with conversion?
  - Candidate: “menu created/imported” and “ordering enabled”.
- What countries/regions do we need tax inference for first?
  - Start with IT/UK/US/EU defaults.

Additional questions to resolve (payments + subscription):
- Do we want subscription billing to require restaurant Stripe Connect at all?
  - Decision (2026-01): No, we are using E1.
- What is the exact Stripe implementation for subscription billing?
  - Stripe Billing subscription on the platform account.
  - Restaurant is stored as a Stripe Customer.
  - Trial starts when payment method is attached.
- What is the definition of “free value” we must prevent?
  - browsing preview is OK?
  - public publishing is NOT OK?
  - QR download/print is NOT OK?
- What is the precise activation gate?
  - publish gate (G1), QR gate (G2), ordering gate (G3), or combination?
- What is the trial policy?
  - duration
  - does it still require bank details up-front?
  - what happens at trial end?
- Who is allowed to complete Stripe Connect onboarding?
  - only owner?
  - manager role?
  - what if multiple managers?
- What is the expected Stripe Connect completion time and what recovery UX do we need?
  - reminders, emails, banners
  - what do we do with restaurants stuck in pending?

## Acceptance Criteria
- New restaurant creation results in:
  - at least 1 tip
  - at least 1 tax
  - at least 1 active locale and exactly 1 default locale
  - current user as active manager employee
- Users can reach menus quickly without being blocked by taxes/tips/localization.
- MOR selection is available early and correctly gates ordering activation.
- Segment dashboard can show:
  - conversion rates per step
  - time to first value
  - drop-off by step/section

---

# Engineering Specification

## Scope

### In scope
- Standardize default provisioning so *all* restaurant creation paths produce a minimally-viable restaurant that is not blocked by:
  - taxes/tips missing
  - locales/default locale missing
  - owner not present as a manager employee
- Replace or relax restaurant-edit hard gating so users can navigate, while still guiding them to complete recommended setup.
- Introduce an MOR decision when entering Ordering/Payments and enforce Stripe KYC gating when the restaurant is MOR.
- Add server-side Segment instrumentation for restaurant onboarding funnel (separate from the signup wizard funnel).

### Not in scope (for this feature)
- Changing the existing 5-step `/onboarding` wizard UX, unless necessary for consistency.
- Full international tax calculation.
- Automatic address geocoding.
- Pricing/plan changes.

## Success Metrics
- **Activation rate**: % of new restaurants reaching “menu created/imported” within 24h.
- **Drop-off rate**: % of users who abandon restaurant setup after create.
- **Time to first value**: time from restaurant creation to first menu created/imported.
- **Ordering enablement**: % of restaurants that enable ordering (and % completing Stripe KYC if restaurant is MOR).

## Current Implementation Constraints (must respect)
- `Restaurant#onboarding_next_section` currently drives a forced-redirect gating in `RestaurantsController#edit`.
- Default provisioning exists in `RestaurantOnboardingJob#create_default_restaurant_settings`, but only for the wizard path.
- Payments MOR is stored via `PaymentProfile#merchant_model` and updated via `Payments::PaymentProfilesController#update`.

## Proposed Architecture

### 1) Central provisioning service
Create a single service that can be called from:
- `RestaurantsController#create`
- `OnboardingController#handle_account_details` when creating a new restaurant
- `RestaurantOnboardingJob#create_restaurant` (optional: use it internally)

Suggested name:
- `RestaurantProvisioningService` (or `RestaurantBootstrapService`)

Responsibilities:
- Ensure owner employee exists (manager)
- Ensure at least one active locale exists and exactly one default active locale
- Ensure at least one tip exists (optional for Smart Menu readiness; still useful for ordering UX)
- Ensure at least one tax exists (optional for Smart Menu readiness; still useful for ordering UX)
- Ensure a default table exists (capacity 4)

Idempotency requirements:
- Must be safe to call multiple times.
- Must not create duplicates.

### 2) Inference utilities
Add small pure functions to infer defaults from `Restaurant#country` (and optionally address text):
- `TaxDefaults.infer(country:)` => `{ name:, taxtype:, taxpercentage: }`
- `LocaleDefaults.infer(country:, user_locale:)` => `['EN', 'IT', ...]` and default selection
- `TipDefaults.infer(country:)` => default percentage

First implementation should be table-driven (simple mapping), not external API-driven.

### 3) Restaurant setup guidance UX (replace hard gating)
Current behavior: hard redirect to next required section.

New behavior:
- Always compute `@onboarding_next = @restaurant.onboarding_next_section`.
- Do not redirect when user visits other sections.
- Show a persistent “Setup banner” while `@onboarding_next.present?`:
  - progress indicator (optional)
  - message: “Recommended next step: <section label>”
  - CTA button: “Continue setup” -> `edit_restaurant_path(..., section: @onboarding_next, onboarding: true)`

Hard gating remains only for actions that cannot operate without setup:
- Enabling ordering (especially when restaurant is MOR)
- Generating/publishing customer-facing Smart Menus if *hard prerequisites* are missing

Hard prerequisites for Smart Menus (per product decision):
- restaurant exists
- at least 1 language (`Restaurantlocale`)
- at least 1 table
- at least 1 staff member (`Employee`)
- at least 1 menu

Taxes and tips are not hard prerequisites.

### 4) Payments MOR decision + KYC gate
Add a first-class UI entry point for MOR selection:
- Where: restaurant `section: 'ordering'` or `section: 'settings'` (whichever currently hosts payments config)
- When: first time entering ordering/payments section and `PaymentProfile` missing OR `merchant_model` unset

Rules:
- If user chooses `restaurant_mor`:
  - require Stripe Connect onboarding completion (ProviderAccount status `enabled`) before allowing ordering activation.
- If user chooses `smartmenu_mor`:
  - ordering activation is allowed without restaurant KYC (subject to existing business rules).

## Data Model / Persistence

### Required (existing)
- `PaymentProfile#merchant_model` already exists.
- `ProviderAccount` exists and has `status`.
- `Restaurantlocale` exists with `dfault` and `status`.

### Proposed additions (optional but recommended)
Add a lightweight DB-backed restaurant onboarding state record for measurement and abandonment jobs:

Option A (preferred): new model `RestaurantOnboardingSession`
- `restaurant_id` (FK)
- `user_id` (FK)
- `status` enum: started, completed, abandoned
- `started_at`, `completed_at`, `abandoned_at`
- `source` (string)
- `last_seen_at` (datetime)
- `last_section` (string)
- `initial_onboarding_next_section` (string)

Option B (minimal): store only timestamps on Restaurant
- `onboarding_started_at`
- `onboarding_completed_at`

Rationale:
- Option A supports cleaner analytics, abandonment detection, and multi-restaurant per user.

## Detailed Requirements

### R1: Provision defaults on restaurant create
When a restaurant is created via `RestaurantsController#create`:
- Call provisioning service after successful save.
- Ensure Smart Menu hard prerequisites are met by default provisioning where feasible (language, table, staff) and the user is guided to create/import a menu.

Additionally:
- Ensure the restaurant address and `country` are collected early (see R1a) so we can infer correct tax defaults.

Behavior notes:
- If restaurant has no address/country, fall back to:
  - user locale (`I18n.locale`) for locale defaults
  - do not create any tax record until `country` is set (product decision)

### R1a: Collect address + country early
To support correct (restaurant-services) VAT defaults, the onboarding flow must ensure `Restaurant#country` (and ideally address fields) are set early.

Minimum requirement:
- The Restaurant “Details” step must include `country` and at least one of:
  - `address1`
  - `city`
  - `postcode`

If `country` is missing:
- Do not create a tax record.
- The UI should prompt the user to complete address/country before enabling any tax-related automation.

### R2: Add current user as manager employee
Ensure a single active manager employee exists for the owner user.
- If an employee exists for (user, restaurant), do not create another.
- Otherwise create an employee record similar to existing patterns.

### R3: Default locale creation + inference
Ensure:
- At least one active `Restaurantlocale` exists.
- Exactly one active locale has `dfault: true`.

Inference rules (v1):
- If `restaurant.country` present:
  - IT -> default `IT`
  - GB/UK -> default `EN`
  - US -> default `EN`
  - else -> default `EN`
- Always include `EN` as a fallback locale.

### R4: Default tax creation + inference
Create one tax if none exists AND `restaurant.country` is present.

Inference rules (v1):
- Use a configurable mapping for **restaurant-services VAT** by country.
- This is a *default suggestion* and must be editable.
- If the country is unknown, do not create a tax record.

Data source and maintenance:
- Primary references:
  - EU “Your Europe” VAT rates page (points to TEDB as authoritative): https://europa.eu/youreurope/business/taxation/vat/vat-rules-rates/index_en.htm
  - Taxes in Europe Database (TEDB): https://ec.europa.eu/taxation_customs/tedb/
- We will maintain a curated `config/vat_restaurant_services_rates.yml` mapping.
- Add a scheduled reminder/process (non-code) to review rates annually.

Phase 1 country coverage:
- All EU Member States + United Kingdom

Behavior for non-VAT countries:
- For countries where restaurant taxation is not VAT-based (e.g. US sales tax), do not infer a tax record automatically.

### R5: Default tip creation
Create one tip if none exists.
- Default 10% unless country overrides.

### R6: Replace “hard redirect” onboarding gating with “guided banner”
In `RestaurantsController#edit`:
- Remove the forced redirect when user visits non-next section.
- Keep `@onboarding_next` exposed to the view.
- Update the sidebar gating (currently uses disabled links) to allow clicking while onboarding is incomplete.

### R7: MOR selection UX + KYC enforcement

UI requirements:
- Add a “Payments / Merchant of Record” card in the relevant section.
- Present both options with clear consequences.
- If `restaurant_mor` is selected and Stripe is not enabled:
  - show a blocking callout with link/button to start Stripe Connect onboarding.
  - disable ordering enablement actions.

Server enforcement:
- Any endpoint that enables ordering must verify:
  - `merchant_model` present
  - if `merchant_model == restaurant_mor`, then Stripe ProviderAccount status is `enabled`

Note:
- MOR selection is explicitly delayed until entering Ordering/Payments.

## Analytics / Instrumentation (Segment)

### Event naming
Use a consistent prefix `restaurant_onboarding_*` and keep existing wizard events unchanged.

### Events and payloads
1. `restaurant_onboarding_started`
- `user_id`
- `restaurant_id`
- `source`
- `initial_next_section`

2. `restaurant_onboarding_step_viewed`
- `restaurant_id`
- `section`
- `next_recommended_section`
- `is_recommended`

3. `restaurant_onboarding_step_completed`
- `restaurant_id`
- `completed_section`
- `next_recommended_section` (after completion)

4. `restaurant_onboarding_completed`
- `restaurant_id`
- `time_to_complete_seconds`

5. `restaurant_onboarding_abandoned`
- `restaurant_id`
- `time_since_start_seconds`
- `last_seen_section`

6. `merchant_model_selected`
- `restaurant_id`
- `merchant_model`
- `stripe_provider_account_status`

7. `stripe_kyc_started` / `stripe_kyc_completed` / `stripe_kyc_failed`
- `restaurant_id`
- `provider_account_id`

### Implementation locations
- Controller-level calls to `AnalyticsService.track_user_event`.
- A periodic job for abandonment detection if Option A session model is implemented.

## Implementation Plan (Phased)

### Phase 1: Provisioning + unblock core setup
- Implement `RestaurantProvisioningService` (idempotent).
- Call it from `RestaurantsController#create`.
- Call it when onboarding wizard creates a new restaurant (to unify behavior).
- Add analytics event `restaurant_onboarding_started` on restaurant create.

### Phase 2: Replace hard gating with guided UX
- Remove forced redirect in `RestaurantsController#edit`.
- Update sidebar disabling logic to allow navigation.
- Add setup banner UI (recommended next step + CTA).
- Add `restaurant_onboarding_step_viewed` events.

### Phase 3: MOR selection + KYC enforcement
- Add MOR selection UI.
- Add server-side enforcement on ordering enablement.
- Emit `merchant_model_selected` and Stripe lifecycle events.

### Phase 3b: Subscription billing gate + anti-free-value enforcement
- Billing architecture decision: E1 (platform bills restaurant; no Connect required for subscription).
- Add a dedicated “Plan & Billing” section (or extend Settings) that:
  - shows current plan
  - allows selecting a plan
  - starts a trial/subscription only after a payment method is on file
- Add a server-side enforcement point on the *activation boundary*:
  - Publish action endpoint (required)
- Emit:
  - `billing_plan_selected`
  - `billing_subscription_started`
  - `billing_subscription_payment_failed`
  - `billing_subscription_canceled`

### Phase 4: Funnel completion + abandonment
- Implement completion detection when `Restaurant#onboarding_next_section` transitions to `nil`.
- Add `restaurant_onboarding_completed`.
- Add abandonment job and emit `restaurant_onboarding_abandoned`.

## Testing Strategy

### Unit tests
- Provisioning service:
  - idempotency (calling twice does not duplicate records)
  - locale default uniqueness
  - tax/tip creation
  - employee creation

### Integration tests
- Restaurant create provisions defaults.
- Restaurant edit does not redirect when onboarding is incomplete (banner present).
- Ordering enablement blocked when `merchant_model == restaurant_mor` and Stripe not enabled.

### Analytics tests
- Stubbing `AnalyticsService` calls in tests (assert event name + key properties).

## Rollout / Migration Plan
- Ship provisioning first (low risk).
- Then ship UX changes behind a feature flag if desired (e.g. `restaurant_onboarding_guided_mode`).
- Enable MOR decision UI for newly created restaurants first.

## Risks
- Incorrect tax inference can cause user distrust; label defaults as editable.
- Removing gating may allow users to land in sections that assume setup exists; ensure those sections degrade gracefully.
- Analytics noise: ensure events are not emitted excessively (debounce step viewed per session/section).

## Open Questions (need your decisions)
1. **Locale inference**: should we prefer restaurant country, user locale, or browser Accept-Language?
2. **Tips**: do we want to seed a default tip automatically for all countries, or only some?
3. **Hard gating**: confirm we only hard-gate Smart Menus on (language + table + staff + menu), and that taxes/tips remain optional.

4. **Billing architecture**: Decision (2026-01): E1 (platform bills without Connect).
5. **Activation boundary**: Decision (2026-01): Publish gate.
6. **Trial policy**: Decision (2026-01): Trial with card/bank up-front.
