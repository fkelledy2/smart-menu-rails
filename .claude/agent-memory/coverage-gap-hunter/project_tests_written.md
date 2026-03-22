---
name: tests_written
description: All test files created during the coverage remediation effort (March 2026), with test counts
type: project
---

## Tests written as of 2026-03-22

Total new tests added: ~256+ (from 3639 baseline → 3895 runs)

### Policy tests (test/policies/)

| File | Tests | Notes |
|------|-------|-------|
| announcement_policy_test.rb | 4 | index/show always true; scope resolves all |
| plan_policy_test.rb | ~6 | admin-only create/update/destroy |
| allergyn_policy_test.rb | ~8 | owner-based show/update/destroy |
| testimonial_policy_test.rb | ~6 | admin/owner-based |
| genimage_policy_test.rb | ~6 | owner-based |
| vision_policy_test.rb | ~4 | analyze?/detect_menu_items? always true |
| ordraction_policy_test.rb | ~8 | dynamic record creation (empty fixture) |
| ordritemnote_policy_test.rb | ~8 | dynamic record creation (empty fixture) |
| ordrparticipant_policy_test.rb | ~8 | anon customer path tested |
| dw_orders_mv_policy_test.rb | ~6 | analytics policy |
| menuavailability_policy_test.rb | ~6 | menu ownership chain |
| restaurantlocale_policy_test.rb | ~6 | restaurant ownership |
| onboarding_policy_test.rb | ~6 | user == record.user |
| ingredient_policy_test.rb | ~8 | is_shared path + super_admin |
| profit_margin_target_policy_test.rb | 10 | effective_from required field |
| menuparticipant_policy_test.rb | 8 | anon customer path |
| analytics_policy_test.rb | 5 | track?/track_anonymous? always true |
| metric_policy_test.rb | 8 | all CRUD user.present? always true |
| onboarding_session_policy_test.rb | 6 | record.user == user |
| track_policy_test.rb | 14 | owns_track? chain |
| restaurantavailability_policy_test.rb | 12 | owns_restaurant_availability? |
| ordritem_policy_test.rb | 16 | anon customer + owner paths |
| ocr_menu_section_policy_test.rb | 7 | owner + admin bypass |
| ocr_menu_item_policy_test.rb | 4 | owner chain through ocr_menu_section |

### Service tests (test/services/)

| File | Tests | Notes |
|------|-------|-------|
| menu_version_activation_service_test.rb | ~10 | scheduled activation, deactivation |
| profit_margin_analytics_service_test.rb | ~8 | dashboard_stats keys |
| inventory_profit_analyzer_service_test.rb | ~8 | urgency values, reorder suggestions |
| country_currency_inference_test.rb | ~15 | pure logic, country→currency mappings |
| establishment_type_inference_test.rb | ~12 | infer_from_google_places_types, labels_for |
| menu_version_diff_service_test.rb | 14 | pure logic, diff structure |
| ingredient_csv_import_service_test.rb | 6 | Tempfile CSV creation |
| menu_version_snapshot_service_test.rb | 10 | snapshot structure, JSON serializability |
| voice_command_intent_service_test.rb | 39 | pure logic, all intents + locales |
| ordr_station_ticket_service_test.rb | 10 | stream_name, submit, rollup |
| restaurant_archival_service_test.rb | 7 | archive!/restore! round-trip |
| restaurant_insights_service_test.rb | 7 | top_performers, slow_movers |
| demo_menu_service_test.rb | 6 | nil guard + attach path |

## Key lessons

- `ordritems.yml` exists with food items (burger, fries, soda) linked to ordrs(:one)
- `ordr_station_ticket_id` has FK constraint — cannot use fake IDs in update_all
- ActionCable.server.stub(:broadcast, nil) {} is the correct pattern to suppress broadcasts
- Empty fixture files that must use dynamic creation: `ordractions.yml`, `ordritemnotes.yml`
