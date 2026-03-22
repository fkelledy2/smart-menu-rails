# Real Dynamic Pricing Plans (Cost-Indexed, Price-Locked at Signup)

## Status
- Priority Rank: #11
- Category: Post-Launch
- Effort: L
- Dependencies: Cost Insights & Pricing Model Publisher (#12), Heroku Cost Inventory (#13); existing `Plan`, `Userplan`, `Payments::Orchestrator`, Stripe integration

## Problem Statement
mellow.menu's subscription pricing is currently static and manually managed. As the platform scales, usage-variable costs (AI/OCR, compute, OpenAI, DeepL) and infrastructure costs will change — making it increasingly difficult to maintain consistent gross margins. Static pricing also makes it hard to react to vendor price changes. This feature introduces versioned, cost-indexed pricing: new signups are billed at the price derived from current running costs plus target margin, while existing customers are never repriced automatically.

## Success Criteria
- A published `PricingModel` is used to set prices for new signups (EUR and USD).
- Prices are locked at the date of signup for the lifetime of the subscription.
- Admin+super_admin can preview and publish new pricing model versions.
- Existing customers are never affected by new pricing model publications.
- Plan changes default to the current pricing model, with admin-approved override to keep original cohort.
- Stripe Prices are created per plan/interval/currency/version.

## User Stories
- As a restaurant owner, I want my subscription price to be stable after signup so I can budget reliably.
- As a mellow.menu operator, I want new signup prices to automatically reflect our running costs so we maintain sustainable margins.
- As a super admin, I want to inspect why a customer pays a specific price so I can handle support queries accurately.

## Functional Requirements
1. `PricingModel` entity: `version` (unique string, e.g. `2026_Q2`), `status` (draft/published/retired), `effective_from` (datetime), `currency` (EUR/USD), `inputs_json` (jsonb), `outputs_json` (jsonb).
2. `PricingModelPlanPrice` entity: `pricing_model_id`, `plan_id`, `interval` (month/year), `price_cents`, `currency`, `stripe_price_id`. Unique index on `[pricing_model_id, plan_id, interval, currency]`.
3. `Userplan` gains applied pricing fields: `pricing_model_id` (FK nullable), `applied_price_cents`, `applied_currency`, `applied_interval`, `applied_stripe_price_id`, `pricing_override_keep_original_cohort`, `pricing_override_by_user_id`, `pricing_override_at`, `pricing_override_reason`.
4. `Pricing::ModelCompiler` service: validates cost inputs, computes plan prices deterministically from cost totals + margin target + plan weights, writes `PricingModelPlanPrice` records.
5. `Pricing::ModelResolver.current` returns the latest published model by `effective_from`.
6. On new signup: resolve current pricing model, resolve plan+interval+currency price, create Stripe checkout session with the resolved `stripe_price_id`, persist `pricing_model_id` and applied price fields on `Userplan`.
7. On plan change (self-serve): customer defaults to current pricing model. Admin/super_admin can override to keep original cohort (logged with reason and approver).
8. Publishing a pricing model: validates draft, creates Stripe Prices for each plan/interval/currency combination, locks the model (immutable after publish), logs publish event with user and timestamp.
9. Published pricing models are immutable — corrections require publishing a new version.
10. Currency resolution at signup: primary source is restaurant's `country` → mapped to EUR or USD. Stored on `Userplan.applied_currency`.
11. Existing customers see "Your pricing version: 2026_Q2" and "Price locked since signup" on their billing page.
12. Admin-only UI (under `Admin::` namespace, not Madmin): pricing model list, draft editor, preview, publish action.

## Non-Functional Requirements
- Only `admin: true AND super_admin: true` users can access pricing model admin screens.
- Published models must be provably immutable (no update routes after `status: 'published'`).
- Stripe Price creation during publish must be transactional: if any Price fails to create, the publish rolls back.
- Pricing computation must be deterministic: same inputs always produce same outputs.
- No regressions in existing signup, plan change, or cancellation flows.

## Technical Notes

### Services
- `app/services/pricing/model_compiler.rb`: computes plan prices from inputs.
- `app/services/pricing/model_resolver.rb`: `current` class method.
- `app/services/pricing/stripe_price_publisher.rb`: creates Stripe Prices via `Payments::Orchestrator`.

### Models / Migrations
- `create_pricing_models`: see schema above.
- `create_pricing_model_plan_prices`: see schema above.
- `add_pricing_fields_to_userplans`: see applied pricing fields above.

### Policies
- `app/policies/pricing_model_policy.rb`: `admin? && super_admin?` for all actions.

### Controllers
- `app/controllers/admin/pricing_models_controller.rb`: list, new, edit (draft only), preview, publish.

### Views
- `app/views/admin/pricing_models/`: index, new/edit, preview (shows computed prices before publish).

### Routes
```ruby
namespace :admin do
  resources :pricing_models do
    member { post :publish }
  end
end
```

### Flipper
- `cost_indexed_pricing` — enables new signup flow to use current pricing model. Off by default until first model is published.

## Acceptance Criteria
1. Admin creates a draft pricing model with cost inputs and target margin; preview shows computed plan prices for EUR and USD.
2. Admin publishes the model; Stripe Prices are created for each plan/interval/currency combination and `stripe_price_id` is persisted.
3. New signup uses the published pricing model's `stripe_price_id`; `Userplan` stores `pricing_model_id` and `applied_price_cents`.
4. A new pricing model can be published; existing customers' `Userplan.pricing_model_id` does not change.
5. Plan change (self-serve) assigns the new plan using the current pricing model's price.
6. Admin approves override: plan change keeps original cohort pricing; `pricing_override_*` fields are populated.
7. Attempting to edit a published pricing model returns an error.
8. Non super_admin user cannot access `/admin/pricing_models` (returns 403 or redirect).

## Out of Scope
- Per-customer negotiated pricing.
- Real-time per-request dynamic pricing.
- Automated vendor invoice ingestion (v1 uses manual cost entry).
- Regionalized pricing beyond EUR/USD.
- Enterprise custom contracts.

## Open Questions
1. Where does the authoritative subscription record live today — `Userplan` only, or also a `RestaurantSubscription` model? Audit before migrations.
2. What is the plan weight / allocation model? Equal weight per plan, or customer-count-weighted? Needs a product decision before `ModelCompiler` can be built.
3. Should annual billing derive from a discount percentage (e.g. 2 months free) or be computed independently from annual cost assumptions?
4. How are existing customers backfilled into a "legacy" pricing model record for auditability?
