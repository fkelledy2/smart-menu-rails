---
name: untested_gaps
description: Remaining coverage gaps by directory as of 2026-03-22, prioritised for next session
type: project
---

## Remaining untested service files (as of 2026-03-22)

High-value, high-line-count:
- `web_menu_processor.rb` (581 lines) — OCR/web scraping, complex, needs mocked HTTP
- `cache_dependency_service.rb` (417 lines) — cache invalidation logic
- `restaurant_archival_service.rb` — DONE (2026-03-22)
- `pdf_menu_processor.rb` (~19.7% covered in RSpec) — partial
- `payments/webhooks/stripe_ingestor.rb` (~29.4% covered) — partial

Medium-value, testable:
- `menu_item_matcher_service.rb` — fuzzy name matching, likely pure logic
- `menu_source_change_detector.rb` — diff detection service
- `ocr_menu_import_broadcast_service.rb` — ActionCable broadcast, simple
- `openai_whisper_transcription_service.rb` — stub OpenAI client
- `smart_menu_ml_client.rb` — stub HTTP
- `whisky_hunter_client.rb` — stub HTTP
- `discovered_restaurant_restaurant_sync_service.rb` — DB operations
- `ai_cost_estimator_service.rb` — likely pure calculation

## Remaining untested policy files

All policies now have tests. Comprehensive coverage achieved for all 48 policies.

## High-value job tests still needed (test/jobs/)

Jobs with no tests (53 total, ~15 have tests):
- `ai_menu_polisher_job.rb` (431 lines) — AI, stub OpenAI
- `menu_export_job.rb`
- `restaurant_archive_job.rb` — coordinate with RestaurantArchivalService
- `restaurant_restore_job.rb`
- Payment jobs (likely partial from RSpec)

## Controller gaps

High-value controllers with low/no Minitest coverage:
- `restaurant_analytics_controller.rb` (325 lines)
- `tablesettings_controller.rb` (298 lines)
- `ordrs_controller.rb` — critical, order lifecycle
- `payments_controller.rb` — critical

## What to tackle next

Priority order for maximum coverage gain:
1. `cache_dependency_service.rb` (417 lines, 0% Minitest)
2. `menu_item_matcher_service.rb` (pure logic)
3. `menu_source_change_detector.rb`
4. `ai_cost_estimator_service.rb`
5. Critical controller request tests (ordrs, payments)
6. `web_menu_processor.rb` (needs heavy mocking)

**Why:** Services are faster to test (no HTTP stack) and yield more lines per test than controllers.
Controllers should be added via request tests (`ActionDispatch::Integration::Session`) not
functional tests, to get realistic coverage of the full request/response cycle.
