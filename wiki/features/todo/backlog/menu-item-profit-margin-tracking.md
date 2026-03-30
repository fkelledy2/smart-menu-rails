# Menu Item Profit Margin Tracking — Phase 4

## Status
- Priority Rank: #35 (Phase 4 only — Phases 1–3 are complete and in production)
- Category: Post-Launch
- Effort: M
- Dependencies: Phases 1–3 complete (production, 2026-03-17); Menu Optimization Agent (#21) consumes Phase 4 output
- Refined: true

## What Is Already Built (Phases 1–3)

Phases 1–3 shipped 2026-03-17 and are fully in production. Do not re-implement any of the following.

**Models in production:**
- `MenuitemCost` — versioned cost history per menu item
- `MenuitemIngredientQuantity` — recipe ingredients with per-quantity costs
- `ProfitMarginTarget` — 3-level (Restaurant / Section / Item) inherited targets
- `Ingredient` — restaurant-scoped, with `cost_per_unit`, `category`, `is_shared`

**Services in production:**
- `AiCostEstimatorService` — GPT-4o cost estimation (called during OCR import)
- `IngredientCsvImportService` — bulk ingredient upload
- `ProfitMarginAnalyticsService` — dashboard statistics engine
- `InventoryProfitAnalyzerService` — low-stock alerts for high-margin items
- `SizeMappingCostService` — per-size profitability

**Jobs in production:**
- `EstimateOcrItemCostsJob` — AI cost estimation during import
- `RecalculateMenuitemCostsJob` — cascade cost recalculation on ingredient price change

**Key Menuitem methods available:** `current_cost`, `profit_margin`, `profit_margin_percentage`, `effective_margin_target`, `margin_status`, `calculate_recipe_cost`, `size_cost_analysis`

Test coverage: 3,568 tests, 10,107 assertions, zero failures.

---

## Problem Statement (Phase 4)

Phases 1–3 give restaurant owners accurate cost data and historical reporting. Phase 4 closes the loop from insight to action: it delivers a structured menu engineering framework (Stars / Plowhorses / Puzzles / Dogs), AI-generated pricing recommendations, and bundling opportunity detection. Without Phase 4, owners can see that an item has a poor margin but have no guided path to fix it. Phase 4 turns the analytics dashboard from a reporting tool into an optimisation tool.

## Success Criteria

- The menu engineering matrix (Stars / Plowhorses / Puzzles / Dogs) is computed per restaurant and rendered as an interactive 2x2 chart (margin vs. popularity)
- AI pricing recommendations are generated per menu item on demand, referencing the item's current cost, margin target, and comparable items — output is a suggested price and one-sentence rationale
- Bundling opportunities are surfaced as ranked suggestions (e.g. "Item A + Item B are frequently ordered together — a bundle at $X achieves your margin target")
- All AI recommendations are advisory only — no automatic price changes without explicit restaurant owner confirmation
- Phase 4 analytics feed `MenuOptimizationAgent` (#21) via a shared service interface

## User Stories

- As a restaurant owner, I want to see which items are Stars (high margin, high popularity) and which are Dogs (low margin, low popularity) so I can make informed decisions about what to promote, reprice, or remove.
- As a restaurant manager, I want AI-generated pricing suggestions for underperforming items so I can act on data without doing manual calculations.
- As a restaurant owner, I want to see bundling opportunities so I can create combination deals that hit my margin targets.
- As a platform admin, I want Phase 4 features gated behind a Flipper flag so I can roll them out to beta restaurants before general availability.

## Functional Requirements

1. Compute `matrix_quadrant` (`:star`, `:plowhorse`, `:puzzle`, `:dog`) per `Menuitem` using rolling 30-day order volume and current `profit_margin_percentage` relative to restaurant's `ProfitMarginTarget`. Recalculate nightly via Sidekiq cron.
2. Render the matrix as a 2x2 scatter chart in the existing Profit Margins dashboard. Use Chart.js (already in use for Phases 1–3) — no new charting library.
3. `MenuEngineering::PricingRecommendationService` — on-demand, takes a `Menuitem` and calls OpenAI GPT-4o with: current cost, current price, margin target, and the restaurant's top 5 comparable items' prices. Returns `{ suggested_price_cents: Integer, rationale: String, confidence: :high|:medium|:low }`.
4. Recommendations are stored in a new `menuitem_ai_recommendations` table (columns: `menuitem_id`, `recommendation_type`, `payload_json`, `generated_at`, `dismissed_at`, `applied_at`). This is the same append-only audit pattern used across the platform.
5. `MenuEngineering::BundlingOpportunityService` — runs nightly via Sidekiq, identifies items frequently co-ordered (using `Ordritem` join data) where the combined margin can be presented as a bundle at or above target. Stores results in `menuitem_bundle_opportunities`.
6. Owner can accept or dismiss each recommendation from the dashboard. On accept: pre-populate the item price edit form with the suggested price — the owner must explicitly save. On dismiss: record `dismissed_at` and hide from dashboard.
7. All Phase 4 AI calls are routed through the existing OpenAI client — not a new API integration.
8. Phase 4 is gated behind a Flipper flag: `profit_margin_phase4`.

## Non-Functional Requirements

- AI pricing calls must respond within 10 seconds; use `async` Sidekiq job + Turbo Stream to push result to the UI when ready
- No automatic price mutation — all changes require explicit restaurant owner action
- Recommendations must be explainable — every suggestion includes a rationale string visible in the UI
- GPT-4o prompt must not include customer PII or order-level personal data
- Matrix quadrant calculation must complete within the Sidekiq job execution window (< 30s for restaurants with up to 500 menu items)

## Technical Notes

- New service: `app/services/menu_engineering/pricing_recommendation_service.rb`
- New service: `app/services/menu_engineering/bundling_opportunity_service.rb`
- New job: `app/jobs/menu_engineering/compute_matrix_job.rb` — nightly Sidekiq cron
- New job: `app/jobs/menu_engineering/detect_bundling_opportunities_job.rb` — nightly Sidekiq cron
- New migrations: `create_menuitem_ai_recommendations`, `create_menuitem_bundle_opportunities`
- Extend existing `ProfitMarginsController` with Phase 4 actions — do not create a new controller
- Pundit: extend `ProfitMarginPolicy` — `recommend?` and `apply_recommendation?` require `:manager` role or above (role checked on `Employee`, not `User`)
- Flipper flag: `profit_margin_phase4`
- Feed output to `MenuOptimizationAgent` (#21) via `MenuEngineering::BundlingOpportunityService#opportunities_for(restaurant)` — the agent spec already references this interface
- The nightly compute jobs should target the read replica for analytics queries (15s timeout); write results to primary

## Acceptance Criteria

1. Given a restaurant with at least 14 days of order history and cost data on all items, the matrix chart renders on the Profit Margins dashboard with all items plotted in the correct quadrant.
2. Given a menu item in the `:dog` quadrant, clicking "Get AI Suggestion" triggers `MenuEngineering::PricingRecommendationService` and displays the result (suggested price + rationale) within 10 seconds.
3. Given the owner clicks "Accept" on an AI price suggestion, the item edit form opens pre-populated with the suggested price; the suggestion remains pending until the owner explicitly saves.
4. Given the owner clicks "Dismiss" on a recommendation, it disappears from the dashboard and `dismissed_at` is set.
5. Given two items are frequently co-ordered (>= 20 times in 30 days) and a bundle price at a 5% discount still meets the restaurant's margin target, a bundling opportunity card is shown on the dashboard.
6. All Phase 4 features are absent for restaurants without the `profit_margin_phase4` Flipper flag enabled.
7. No pricing changes are persisted without explicit owner save action.

## Out of Scope

- Fully automatic price changes (owner-confirmation is always required in this iteration)
- Integration with POS systems for live price sync
- Multi-restaurant bundle campaigns
- Customer-facing bundle UI (bundle pricing is advisory only — staff apply it manually at this stage)

## Open Questions

1. Should bundling opportunities be surfaced as a new dashboard tab, or as a card/panel within the existing Profit Margins dashboard?
2. What is the minimum number of co-orders required before a bundle suggestion is shown? (Suggestion: 20 co-orders in 30 days — confirm with product.)
3. Does Phase 4's `profit_margin_phase4` flag replace or gate-in-addition-to the existing Phase 3 features, or is it purely additive?
