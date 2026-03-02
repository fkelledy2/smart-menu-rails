# Dead Code Audit — Mellow.menu Codebase

**Date**: 2026-03-01
**Scope**: Full codebase — backend (Ruby/Rails), frontend (JS/SCSS), views, tests
**Method**: Automated grep + reference counting across `app/`, `config/`, `lib/`, `test/`, `spec/`

---

## Executive Summary

| Category | Dead Items Found | Est. Lines Removable |
|---|---|---|
| Empty view partials (0-byte stubs) | 6 files | 0 (already empty) |
| Orphaned view partials & directories | 11+ files/dirs | ~200 |
| Superseded view partial | 1 file | ~88 |
| Empty helper files (stub-only) | 38 files | ~76 |
| Unreferenced jobs | 10 jobs | ~2,500 |
| Unreferenced services | 12 services | ~8,000 |
| Unreferenced model (`ResourceLock`) | 1 model | ~5 |
| Unreferenced model concerns | 3 concerns | ~200 |
| Unreferenced Stimulus controllers | 4 controllers | ~300 |
| Unreferenced ViewComponents | 2 components | ~100 |
| Unreferenced serializers | 9 serializers | ~200 |
| Orphaned Pundit policies (no authorize call) | 12 policies | ~300 |
| Unused gems | 8 gems | Gemfile cleanup |
| Commented-out code blocks | 30+ blocks | ~500 |
| Empty directories | 5 dirs | 0 |
| Duplicate/superseded services | 2 pairs | ~12,000 |
| **Estimated total removable** | | **~24,000+ lines** |

---

## 1. Empty View Partials (0-Byte Stubs)

These files are **empty (0 bytes)** — leftover stubs from when modals were consolidated into `_showModals.erb`. Safe to delete immediately.

| File | Status |
|---|---|
| `app/views/smartmenus/_showFilterOrderModal.erb` | Empty, 0 bytes |
| `app/views/smartmenus/_showAddItemToOrderModal.erb` | Empty, 0 bytes |
| `app/views/smartmenus/_showAddNameToParticipantModal.erb` | Empty, 0 bytes |
| `app/views/smartmenus/_showOpenOrderModal.erb` | Empty, 0 bytes |
| `app/views/smartmenus/_showPayOrderModal.erb` | Empty, 0 bytes |
| `app/views/smartmenus/_showRequestBillModal.erb` | Empty, 0 bytes |

**Action**: Delete all 6 files. No code references them.

---

## 2. Orphaned View Partials & Directories

### Partials never rendered from any view or controller

| File | Notes |
|---|---|
| `app/views/smartmenus/_empty_states.html.erb` | No render call found in any view. May be loaded via JS innerHTML — **verify before deleting** |
| `app/views/smartmenus/_welcome_banner.html.erb` | Not rendered from any `.erb`. JS Stimulus controller exists but partial not rendered — **verify** |
| `app/views/smartmenus/_allergen_legend_modal.html.erb` | **Superseded** by `_allergen_combined_modal.html.erb`. Only ref is an i18n key string match. Safe to delete. |
| `app/views/menus/_form_2025_example.html.erb` | Example/template file. Safe to delete. |
| `app/views/menus/sections/_design_2025.html.erb` | Never rendered. Safe to delete. |
| `app/views/restaurants/sections/_address_2025.html.erb` | Never rendered. Safe to delete. |
| `app/views/restaurants/sections/_qrcodes_2025.html.erb` | Never rendered. Safe to delete. |
| `app/views/shared/_inline_save_indicator.html.erb` | Never rendered. Safe to delete. |
| `app/views/shared/_skeleton_frame.html.erb` | Never rendered. Safe to delete. |
| `app/views/shared/_status_badge_2025.html.erb` | Never rendered. Safe to delete. |
| `app/views/shared/_sticky_edit_actions_2025.html.erb` | Never rendered. Safe to delete. |
| `app/views/kitchen_dashboard/_order_card.html.erb` | Never rendered. Safe to delete. |

### Empty view directories (no files)

| Directory | Action |
|---|---|
| `app/views/menu_imports/` | Empty dir. Delete. |
| `app/views/offline/` | Empty dir. Delete. |

**Action**: Delete all confirmed-safe files. Verify `_empty_states` and `_welcome_banner` manually before removal.

---

## 3. Empty Helper Files (Stub-Only)

**38 helper files** contain only an empty module definition (2 lines each). Rails auto-generates these but they add noise.

```
app/helpers/allergyns_helper.rb        app/helpers/contacts_helper.rb
app/helpers/employees_helper.rb        app/helpers/features_helper.rb
app/helpers/features_plans_helper.rb   app/helpers/genimages_helper.rb
app/helpers/ingredients_helper.rb      app/helpers/inventories_helper.rb
app/helpers/kitchen_dashboard_helper.rb app/helpers/menuavailabilities_helper.rb
app/helpers/menuitemlocales_helper.rb   app/helpers/menuitems_helper.rb
app/helpers/menulocales_helper.rb       app/helpers/menuparticipants_helper.rb
app/helpers/menus_helper.rb             app/helpers/menusectionlocales_helper.rb
app/helpers/metrics_helper.rb           app/helpers/onboarding_helper.rb
app/helpers/ordractions_helper.rb       app/helpers/ordritemnotes_helper.rb
app/helpers/ordritems_helper.rb         app/helpers/ordrparticipants_helper.rb
app/helpers/ordrs_helper.rb             app/helpers/payments_helper.rb
app/helpers/plans_helper.rb             app/helpers/restaurantavailabilities_helper.rb
app/helpers/restaurantlocales_helper.rb app/helpers/restaurants_helper.rb
app/helpers/sessions_helper.rb          app/helpers/sizes_helper.rb
app/helpers/smartmenus_helper.rb        app/helpers/tablesettings_helper.rb
app/helpers/tags_helper.rb              app/helpers/taxes_helper.rb
app/helpers/testimonials_helper.rb      app/helpers/tips_helper.rb
app/helpers/tracks_helper.rb            app/helpers/userplans_helper.rb
```

**Action**: Delete all 38 files. They contain no methods.

---

## 4. Unreferenced Jobs (Never Called)

These jobs have **zero references** outside their own file — never enqueued by any controller, model, service, or cron config.

| Job | File | Lines |
|---|---|---|
| `BackfillDemoMenuInactiveJob` | `backfill_demo_menu_inactive_job.rb` | ~20 |
| `BackfillDemoMenuJob` | `backfill_demo_menu_job.rb` | ~30 |
| `EnforceRestaurantMenuPlanLimitJob` | `enforce_restaurant_menu_plan_limit_job.rb` | ~130 |
| `EnforceRestaurantPlanLimitJob` | `enforce_restaurant_plan_limit_job.rb` | ~40 |
| `MenuSourceChangeDetectionJob` | `menu_source_change_detection_job.rb` | ~15 |
| `OcrMenuImportReprocessJob` | `ocr_menu_import_reprocess_job.rb` | ~130 |
| `PerformanceMonitoringJob` | `performance_monitoring_job.rb` | ~140 |
| `RestaurantOnboardingJob` | `restaurant_onboarding_job.rb` | ~350 |
| `ResyncApprovedDiscoveredRestaurantsJob` | `resync_approved_discovered_restaurants_job.rb` | ~25 |
| `SpotifyTrackPlayerJob` | `spotify_track_player_job.rb` | ~20 |

**Note**: Some jobs with 1 reference are called only from within other services (e.g., `AiMenuPolisherJob`, `CityDiscoveryJob`). If those services are also dead, the jobs are transitively dead. Verify the call chain before removing.

**Action**: Delete all 10 jobs. Update any test files that reference them.

---

## 5. Unreferenced Services

### Completely unreferenced (0 callers outside own file)

| Service | File | Lines | Notes |
|---|---|---|---|
| `AnalyticsReportingServiceV2` | `analytics_reporting_service_v2.rb` | ~300 | Calls V1 internally but nothing calls V2 |
| `BaseService` | `base_service.rb` | ~190 | Abstract base, but no service inherits from it |
| `CacheMetricsService` | `cache_metrics_service.rb` | ~400 |  |
| `CacheUpdateService` | `cache_update_service.rb` | ~550 |  |
| `CapacityPlanningService` | `capacity_planning_service.rb` | ~350 |  |
| `CdnAnalyticsService` | `cdn_analytics_service.rb` | ~130 |  |
| `CdnPurgeService` | `cdn_purge_service.rb` | ~130 |  |
| `GeoRoutingService` | `geo_routing_service.rb` | ~150 |  |
| `OrderStateReducer` | `order_state_reducer.rb` | ~50 |  |
| `RedisPipelineService` | `redis_pipeline_service.rb` | ~250 |  |
| `RegionalPerformanceService` | `regional_performance_service.rb` | ~210 |  |
| `WineSizeSeeder` | `wine_size_seeder.rb` | ~40 |  |

### Likely dead (only called from another dead service)

| Service | Called From | Notes |
|---|---|---|
| `AnalyticsReportingService` (V1) | Only from `AnalyticsReportingServiceV2` | V2 is unreferenced → V1 is transitively dead |
| `OpenaiClient` | Internal only (base class for nothing active?) | Verify — may be used by `openai_client.rb` in jobs |

**Action**: Delete the 12 confirmed-dead services. Verify `AnalyticsReportingService` and `OpenaiClient` call chains before removing.

---

## 6. Duplicate / Superseded Services

| Original | Replacement | Status |
|---|---|---|
| `advanced_cache_service.rb` (51KB!) | `advanced_cache_service_v2.rb` (6KB) | V1 has 153 refs, V2 has 8. V1 is the active one. **Delete V2** (unused). |
| `analytics_reporting_service.rb` | `analytics_reporting_service_v2.rb` | Both unreferenced from controllers. **Delete both.** |

**Action**: Delete `advanced_cache_service_v2.rb` and both analytics reporting services.

---

## 7. Unreferenced Model

| Model | File | Notes |
|---|---|---|
| `ResourceLock` | `resource_lock.rb` | Zero references anywhere in `app/`, `config/`, `lib/`. Table exists in DB but model is never used. |

**Action**: Delete `resource_lock.rb`. Optionally create a migration to drop the `resource_locks` table.

---

## 8. Unreferenced Model Concerns

| Concern | File | Notes |
|---|---|---|
| `Localisable` | `app/models/concerns/localisable.rb` | Never included in any model |
| `QueryMonitoring` | `app/models/concerns/query_monitoring.rb` | Never included |
| `SoftDeletable` | `app/models/concerns/soft_deletable.rb` | Never included |

**Action**: Delete all 3 concern files.

---

## 9. Unreferenced Stimulus Controllers

| Controller | File | Notes |
|---|---|---|
| `hello` | `hello_controller.js` | Default Stimulus scaffold. Never used in views. |
| `cart-badge` | `cart_badge_controller.js` | Zero view references. |
| `lazy-stripe` | `lazy_stripe_controller.js` | Zero view references. |
| `ocr-upload` | `ocr_upload_controller.js` | Zero view references. |

**Action**: Delete all 4 files. Remove registrations from `app/javascript/controllers/index.js`.

---

## 10. Unreferenced ViewComponents

| Component | Notes |
|---|---|
| `ActionMenuComponent` | 0 render calls in views |
| `StatusBadgeComponent` | 0 render calls in views |

**Action**: Delete both `.rb` and `.html.erb` files for each component (4 files total).

---

## 11. Unreferenced Serializers

| Serializer | Notes |
|---|---|
| `FeatureSerializer` | 0 refs |
| `FeaturesPlanSerializer` | 0 refs |
| `MenuitemlocaleSerializer` | 0 refs |
| `MenulocaleSerializer` | 0 refs |
| `MenuparticipantSerializer` | 0 refs |
| `MenusectionlocaleSerializer` | 0 refs |
| `RestaurantlocaleSerializer` | 0 refs |
| `TestimonialSerializer` | 0 refs |
| `UserplanSerializer` | 0 refs |

**Action**: Delete all 9 serializer files.

---

## 12. Orphaned Pundit Policies

Most policies are implicitly resolved by Pundit convention (`authorize @model` → `ModelPolicy`). The following have **no matching `authorize` call** anywhere in the codebase:

| Policy | Notes |
|---|---|
| `AnalyticsPolicy` | No `authorize @analytics` call |
| `AnnouncementPolicy` | No `authorize @announcement` call |
| `DwOrdersMvPolicy` | No `authorize @dw_orders_mv` call |
| `FeaturePolicy` | No `authorize @feature` call |
| `MenuitemSizeMappingPolicy` | No `authorize @menuitem_size_mapping` call |
| `OcrMenuItemPolicy` | No `authorize @ocr_menu_item` call |
| `OcrMenuSectionPolicy` | No `authorize @ocr_menu_section` call |
| `OnboardingSessionPolicy` | No `authorize @onboarding_session` call |
| `PlanPolicy` | No `authorize @plan` call |
| `RestaurantMenuPolicy` | No `authorize @restaurant_menu` call |
| `StaffInvitationPolicy` | No `authorize @staff_invitation` call (but `authorize @invitation` may exist) |
| `VisionPolicy` | No `authorize @vision` call |

**Action**: Verify each policy is truly unused (check for `policy_scope` or `authorize` with different variable names). Delete confirmed-dead policies.

---

## 13. Unused Gems

### Confirmed unused (zero references in application code)

| Gem | Gemfile Line | Notes |
|---|---|---|
| `cityhash` | `gem 'cityhash'` | Zero refs. Likely replaced by IdentityCache's built-in hashing. |
| `allow_numeric` | `gem 'allow_numeric'` | Zero refs. |
| `cropper_rails` | `gem 'cropper_rails'` | Zero refs. Image cropping not implemented. |
| `gmaps-autocomplete-rails` | `gem 'gmaps-autocomplete-rails'` | Zero refs. Google Maps autocomplete not used. |
| `seed_dump` | `gem 'seed_dump'` | Zero refs. Dev tool, never invoked. |

### Unused OmniAuth providers (commented out or no config)

| Gem | Notes |
|---|---|
| `omniauth-facebook` | No Devise config for Facebook provider |
| `omniauth-github` | Config line is commented out |
| `omniauth-twitter` | No Devise config for Twitter provider |

**Action**: Remove all 8 gems from `Gemfile`. Run `bundle install`.

---

## 14. Commented-Out Code Blocks (>4 Lines)

Major blocks of commented-out code that should be removed:

| File | Lines | Size |
|---|---|---|
| `app/controllers/metrics_controller.rb` | 246–335 | **90 lines** |
| `app/controllers/api/v1/vision_controller.rb` | 8–28, 59–69 | 32 lines |
| `app/controllers/ocr_menu_items_controller.rb` | 17–26 | 10 lines |
| `app/controllers/metrics_controller.rb` | 121–129 | 9 lines |
| `app/services/localize_menu_service.rb` | multiple blocks | ~40 lines total |
| `app/controllers/concerns/query_cacheable.rb` | multiple blocks | ~25 lines |
| `app/services/openai_client.rb` | multiple blocks | ~20 lines |

**Action**: Remove all commented-out code blocks. Use git history if code is ever needed again.

---

## 15. Empty Directories

| Directory | Action |
|---|---|
| `app/controllers/restaurant/` | Delete |
| `app/controllers/restaurant_module/` | Delete |
| `app/controllers/ai/` | Delete |
| `app/javascript/custom/` | Delete |
| `app/javascript/orders/` | Delete |
| `app/javascript/packs/` | Delete |
| `app/javascript/plugin/` | Delete |
| `app/javascript/services/` | Delete |
| `app/javascript/shared/` | Delete |
| `app/views/menu_imports/` | Delete |
| `app/views/offline/` | Delete |
| `app/errors/` | Delete |

**Action**: Delete all empty directories.

---

## 16. Unused JS Utilities

| File | Refs | Notes |
|---|---|---|
| `app/javascript/utils/bindTableSelectorSearch.test.js` | 0 | Test file for a util — not run by any test runner |
| `app/javascript/utils/tabulator-lite.js` | 0 | Never imported |

**Action**: Delete both files.

---

## 17. Unused Middleware

| Middleware | Notes |
|---|---|
| `performance_monitoring_middleware.rb` | Not registered in `config/` |
| `performance_tracker.rb` | Not registered in `config/` |

**Action**: Delete both files.

---

## Phased Removal Plan

### Phase 1 — Safe Deletes (No Logic Changes)

**Risk: None. These files are confirmed unreferenced.**

1. Delete 6 empty modal stubs in `smartmenus/`
2. Delete 10 orphaned view partials + 2 empty view dirs
3. Delete `_allergen_legend_modal.html.erb` (superseded)
4. Delete 38 empty helper files
5. Delete 12 empty directories
6. Delete 2 unused JS utils
7. Delete 2 unused middleware files
8. Delete 3 unused model concerns

**Estimated**: ~50 files removed, 0 logic changes.

### Phase 2 — Unreferenced Code Removal

**Risk: Low. Verify each item has no indirect/dynamic references.**

1. Delete 10 unreferenced jobs
2. Delete 12 unreferenced services + 1 superseded V2 service
3. Delete `ResourceLock` model
4. Delete 4 unused Stimulus controllers + update `index.js`
5. Delete 2 unused ViewComponents (4 files)
6. Delete 9 unused serializers
7. Remove 8 unused gems from `Gemfile` + `bundle install`

**Estimated**: ~40 files removed, ~12,000 lines.

### Phase 3 — Commented Code & Policy Cleanup

**Risk: Low–Medium. Requires manual review.**

1. Remove all commented-out code blocks (30+ blocks, ~500 lines)
2. Verify and delete 12 orphaned Pundit policies
3. Verify `_empty_states.html.erb` and `_welcome_banner.html.erb` usage

**Estimated**: ~20 files affected, ~800 lines.

### Phase 4 — Test Suite Updates

After each phase, run the full test suite and:

1. Delete tests for removed models/jobs/services
2. Fix any failures caused by removed files
3. Verify no regressions

```bash
# Run full test suite after each phase
bin/rails test
bundle exec rspec
```

---

## Verification Commands

```bash
# Check for broken renders after view deletions
bin/rails routes | grep -i "No route"
RAILS_ENV=test bin/rails runner "ApplicationController.descendants"

# Check for missing constants after model/service deletions
RAILS_ENV=test bin/rails runner "Rails.application.eager_load!"

# Check for broken Stimulus controllers
grep -rn "data-controller" app/views/ --include='*.erb' | \
  grep -oP 'data-controller="[^"]*"' | sort -u

# Verify no broken imports
node -e "require('app/javascript/controllers/index.js')" 2>&1
```
