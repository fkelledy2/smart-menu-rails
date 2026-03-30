---
name: coverage_baseline
description: Coverage baseline (March 2026), gap analysis, and milestone targets for the Smart Menu remediation effort
type: project
---

## Current state (as of 2026-03-29)

- CI COVERAGE_MIN: 50 (set in `.github/workflows/ci.yml`, not 60 as previously assumed)
- SimpleCov merge strategy: `use_merging true` (1-hour timeout), three result sets: Minitest, RSpec, Integration
- Total app Ruby lines: ~58,824
- Current merged coverage estimated at 40–42% based on prior sessions + test count
- Target to be CI-safe: 50% (current CI gate); aspirational engineering target: 60%

**Why the CI minimum matters:** `COVERAGE_MIN=50` in ci.yml; `.simplecov` uses `minimum_coverage ENV['COVERAGE_MIN'].to_i`. Running a single test suite
gives misleading numbers — only the merged result counts.

## Source vs test file counts (2026-03-29)

| Layer       | Source files | Test files | Gap   |
|-------------|-------------|------------|-------|
| Services    | 119         | 109        | 10    |
| Jobs        | 67          | 58         | 9     |
| Models      | 119         | 128        | 0     |
| Policies    | 62          | 56         | 9 (stubs) |
| Controllers | 159         | 89         | 70    |
| Channels    | 7           | 1          | 6     |

## Gap calculation (2026-03-29)

- Current coverage: ~40%
- CI minimum: 50%
- Gap to CI gate: ~10 percentage points (~5,900 lines)
- Gap to engineering target: ~20 pp (~11,800 lines)
- Total app lines: ~58,824

## Milestone targets

| Milestone | Target | Key deliverables | Status |
|-----------|--------|-----------------|--------|
| Phase 1   | 45%    | Payment services (orchestrator, stripe_adapter, ledger, split_plan_upsert) + 9 missing policies + 5 channels | COMPLETE (session 3) |
| Phase 2   | 50%    | Top 12 untested controllers (ordrs, ordritems, payments subs/webhooks, employees, menus/*) + 9 missing jobs | COMPLETE (session 5) |
| Phase 3   | 55%+   | Remaining controller stubs (8 files), concern tests, web_menu_processor, auto_pay/capture_service deepening | NOT STARTED |

## Session 5 additions (2026-03-30)

8 new test files, 95 new tests:
- restaurant_menus_controller_test.rb (15 tests)
- payments/subscriptions_controller_test.rb (12 tests)
- ordrparticipants_controller_test.rb (10 tests)
- staff_invitations_controller_test.rb (10 tests)
- menus/sharing_controller_test.rb (10 tests)
- receipt_deliveries_controller_test.rb (8 tests)
- payments/webhooks_controller_test.rb (4 tests)
- admin/discovered_restaurants_controller_test.rb (26 tests)

Phase 2 COMPLETE. Estimated coverage: ~49-52%.

## Session 4 additions (2026-03-30)

10 new test files, 71 new tests:
- employees_controller_test.rb (21 tests), menus/versions_controller_test.rb (11 tests), menus/ai_controller_test.rb (12 tests)
- crm/process_calendly_webhook_job_test.rb (3), crm/send_lead_email_job_test.rb (4)
- spotify_playlist_sync_job_test.rb (4), discovered_restaurant_refresh_place_details_job_test.rb (5)
- menu_item_image_batch_job_test.rb (3), menu_item_image_context_batch_job_test.rb (3), discovered_restaurant_web_menu_scrape_job_test.rb (4)

## Session 3 additions (2026-03-29)

7 new test files, ~72 new tests:
- orchestrator_test.rb (12 tests), stripe_adapter_test.rb (8 tests), split_plan_upsert_service_test.rb (14 tests)
- kitchen_channel_test.rb (12 tests), menu_editing_channel_test.rb (13 tests)
- ordrs_controller_test.rb (13 tests), ordritems_controller_test.rb (12 tests)

Phase 2 next priorities: payments_controller, employees_controller, menus_controller, remaining 9 Sidekiq jobs

## Known stubs (test file exists but 0 tests)

- `test/controllers/payments_controller_test.rb` — pure stub, no test methods
- `test/controllers/sessions_controller_test.rb` — pure stub
- `test/controllers/features_plans_controller_test.rb` — pure stub
- `test/services/payments/funds_flow_router_test.rb` — only 1 test
- `test/services/payments/split_plan_calculator_test.rb` — 3 tests (minimal)
- `test/jobs/payments/reconciliation_job_test.rb` — stub

## Coverage ratchet

CI `COVERAGE_MIN` is currently 50. Once Phase 2 is complete, raise to 52; Phase 3 raise to 55.
Path: `.github/workflows/ci.yml` line ~162, env: `COVERAGE_MIN: 50`.
