---
name: untested_gaps
description: Remaining coverage gaps by directory as of 2026-03-29, prioritised for next session
type: project
---

## Critical — untested payment services (0% Minitest coverage)

| File | Lines | Risk |
|------|-------|------|
| `payments/orchestrator.rb` | 132 | CRITICAL — routes all payment charges |
| `payments/providers/stripe_adapter.rb` | 156 | CRITICAL — Stripe checkout + auto-pay intent |
| `payments/ledger.rb` | 33 | CRITICAL — financial audit trail |
| `payments/split_plan_upsert_service.rb` | 75 | HIGH — bill-split persistence |
| `payments/setup_intent_service.rb` | 44 | HIGH — card-on-file setup |
| `payments/providers/stripe_connect.rb` | 109 | HIGH — Stripe Connect OAuth |
| `payments/refunds/creator.rb` | 49 | HIGH — refunds |
| `auto_pay/capture_service.rb` | 220 | CRITICAL — zero-dollar path + preconditions need more depth |

Note: `auto_pay_capture_service_test.rb` EXISTS with precondition tests, but the success/failure
paths that call Orchestrator and transition order state are not covered.

## Critical — untested controllers (0% Minitest coverage)

| File | Lines | Risk |
|------|-------|------|
| `ordrs_controller.rb` | 677 | CRITICAL — core order lifecycle |
| `ordritems_controller.rb` | 483 | CRITICAL — item CRUD + line-item ordering |
| `payments/subscriptions_controller.rb` | 181 | CRITICAL — subscription billing |
| `payments/webhooks_controller.rb` | 102 | CRITICAL — inbound Stripe/Square events |
| `employees_controller.rb` | 357 | HIGH — RESOLVED 2026-03-30 (21 tests) |
| `admin/discovered_restaurants_controller.rb` | 589 | HIGH — discovery admin |
| `restaurants/analytics_controller.rb` | 308 | HIGH — analytics reads |
| `menus/ai_controller.rb` | 168 | HIGH — RESOLVED 2026-03-30 (12 tests) |
| `menus/versions_controller.rb` | 173 | HIGH — RESOLVED 2026-03-30 (11 tests) |
| `restaurant_menus_controller.rb` | 246 | HIGH — menu management |
| `menus/sharing_controller.rb` | 121 | MEDIUM |
| `menus/localization_controller.rb` | 82 | MEDIUM |
| `restaurantlocales_controller.rb` | 315 | MEDIUM |
| `ordrparticipants_controller.rb` | 170 | MEDIUM |
| `menuparticipants_controller.rb` | 172 | MEDIUM |
| `staff_invitations_controller.rb` | 108 | MEDIUM |
| `receipt_deliveries_controller.rb` | 135 | MEDIUM |

## Controller stubs (file exists but 0 tests)

- `payments_controller_test.rb` — full stub
- `sessions_controller_test.rb` — full stub
- `features_plans_controller_test.rb` — full stub

## Missing policy tests — ALL RESOLVED 2026-03-29

All 9 policies now have test files. See project_tests_written.md.

## Missing ActionCable channel tests

### RESOLVED 2026-03-29
- `floorplan_channel.rb` — test/channels/floorplan_channel_test.rb (5 tests)
- `user_channel.rb` — test/channels/user_channel_test.rb (4 tests)
- `station_channel.rb` — test/channels/station_channel_test.rb (9 tests)

### Still outstanding
| Channel | Lines | Key coverage target |
|---------|-------|---------------------|
| `kitchen_channel.rb` | 94 | subscribe, stream_from with valid session |
| `menu_editing_channel.rb` | 91 | subscribe, unauth rejection |
| `presence_channel.rb` | 45 | subscribe, track presence |

## Missing job tests

### RESOLVED 2026-03-29
- `payments/webhook_ingest_job.rb` — test/jobs/payments/webhook_ingest_job_test.rb (6 tests)
- `menu_version_scheduler_job.rb` — test/jobs/menu_version_scheduler_job_test.rb (12 tests)

### RESOLVED 2026-03-30
All outstanding jobs now have tests:
- `menu_item_image_batch_job.rb` — test/jobs/menu_item_image_batch_job_test.rb (3 tests)
- `menu_item_image_context_batch_job.rb` — test/jobs/menu_item_image_context_batch_job_test.rb (3 tests)
- `discovered_restaurant_web_menu_scrape_job.rb` — test/jobs/discovered_restaurant_web_menu_scrape_job_test.rb (4 tests)
- `discovered_restaurant_refresh_place_details_job.rb` — test/jobs/discovered_restaurant_refresh_place_details_job_test.rb (5 tests)
- `spotify_playlist_sync_job.rb` — test/jobs/spotify_playlist_sync_job_test.rb (4 tests)
- `crm/send_lead_email_job.rb` — test/jobs/crm/send_lead_email_job_test.rb (4 tests)
- `crm/process_calendly_webhook_job.rb` — test/jobs/crm/process_calendly_webhook_job_test.rb (3 tests)

### All app/jobs/ source files now have corresponding test files (as of 2026-03-30)

## Untested services

### RESOLVED 2026-03-29
- `payments/ledger.rb` — test/services/payments/ledger_test.rb (13 tests)

### Still outstanding
| File | Lines | Risk |
|------|-------|------|
| `web_menu_processor.rb` | 581 | HIGH — needs heavy mocking |
| `menu_discovery/website_contact_extractor.rb` | 315 | MEDIUM |
| `auto_pay/capture_service.rb` | 220 | — test EXISTS, needs deepening |
| `google_places/city_discovery.rb` | 182 | MEDIUM |
| `menu_discovery/robots_txt_checker.rb` | 135 (shared w/ existing test) | LOW |
| `payments/providers/stripe_connect.rb` | 109 | HIGH |
| `payments/split_plan_upsert_service.rb` | 75 | HIGH |
| `crm/lead_email_sender.rb` | 80 | MEDIUM |
| `payments/setup_intent_service.rb` | 44 | HIGH |

## Controller status (updated 2026-03-30 after session 5)

### RESOLVED in session 5
- `restaurant_menus_controller.rb` — 15 tests
- `payments/subscriptions_controller.rb` — 12 tests
- `ordrparticipants_controller.rb` — 10 tests
- `staff_invitations_controller.rb` — 10 tests
- `menus/sharing_controller.rb` — 10 tests
- `receipt_deliveries_controller.rb` — 8 tests
- `payments/webhooks_controller.rb` — 4 tests
- `admin/discovered_restaurants_controller.rb` — 26 tests

### Still outstanding (Phase 3 targets)
| File | Lines | Risk | Notes |
|------|-------|------|-------|
| `restaurants/analytics_controller.rb` | 308 | HIGH | analytics reads |
| `restaurantlocales_controller.rb` | 315 | MEDIUM | locale CRUD |
| `menuparticipants_controller.rb` | 172 | MEDIUM | customer-facing |
| `menus/localization_controller.rb` | 82 | MEDIUM | localization |
| `payments_controller_test.rb` | — | MEDIUM | stub only |
| `sessions_controller_test.rb` | — | MEDIUM | stub only |
| `features_plans_controller_test.rb` | — | LOW | stub only |

## Priority order for Phase 3 (updated 2026-03-30)

1. `restaurants/analytics_controller.rb` (308 lines) — highest remaining gain
2. `restaurantlocales_controller.rb` (315 lines) — CRUD on locale records
3. `menuparticipants_controller.rb` (172 lines) — customer smart menu flow
4. Deepening: `auto_pay/capture_service.rb` (success + error paths)
5. Service tests: `payments/setup_intent_service.rb`, `payments/refunds/creator.rb`
