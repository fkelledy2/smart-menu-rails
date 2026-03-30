# Codebase Improvements: Industry Best Practices Audit

Generated: 2026-03-20

Comprehensive audit of the Smart Menu codebase against industry best practices. Findings are grouped by category with a prioritised remediation plan at the end.

---

## 1. Security

### Critical

**Hardcoded credential in source code**
`app/services/deepl_api_service.rb:9` contains a real DeepL API key hardcoded as `TEST_API_KEY = '9079cde6-...'`. Even if it is a free-tier key, committing credentials to source is a major security violation — it will be in git history permanently.

Fix: Rotate the key immediately. Replace with `Rails.application.credentials.dig(:deepl, :test_api_key)` gated behind `Rails.env.test?`.

**CSP is report-only and uses unsafe directives**
`config/initializers/content_security_policy.rb` has `config.content_security_policy_report_only = true` — the policy is never enforced. Additionally, `script_src :unsafe_inline, :unsafe_eval` and `style_src :unsafe_inline` negate most XSS protection. The comment says "once violations are reviewed" — this has been left unresolved.

Fix: Set a `report_uri` to a Sentry or CSP report endpoint. Eliminate `unsafe_eval` first. Migrate inline scripts to Stimulus controllers, then remove `unsafe_inline`. Switch to enforce mode.

**CSRF bypass on MenusController**
`skip_before_action :verify_authenticity_token, only: %i[create_version activate_version]` in `menus_controller.rb`. These are state-mutating POST actions — skipping CSRF protection without a documented reason is a vulnerability.

Fix: Restore CSRF protection and use `requestjs-rails` (already in the Gemfile) to send the correct headers from Stimulus.

**JWT revocation is non-durable**
`jwt_service.rb` stores revoked token JTIs in `Rails.cache`. If the cache is cleared (deploy, Redis flush, restart), all revoked tokens become valid again. `JwtService::SECRET_KEY` is also `secret_key_base` — rotating the master key invalidates all live user sessions simultaneously.

Fix: Store revocations in a dedicated Redis key (separate from the primary cache) with explicit TTL, or switch to a database denylist table for tokens that require revocation guarantees.

### High

**Rate limiting is per-process, not shared**
`rack_attack.rb` configures `Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new`. On a multi-dyno/multi-worker deployment each process has its own counter — an attacker can make N×limit requests by distributing across dynos.

Fix: Change to `Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(url: ENV['REDIS_URL'])`.

**`require_master_key` is commented out**
`config/environments/production.rb` has `# config.require_master_key = true`. If `RAILS_MASTER_KEY` is absent, the app boots without credentials rather than failing fast.

Fix: Uncomment it.

**Sensitive fields not encrypted at rest**
Only `provider_account.rb` uses ActiveRecord Encryption. Payment-related data in `payment_attempt`, `payment_profile`, `ordr_split_payment`, and PII in `user` and `employee` models is stored in plaintext. Rails 7 ships with `encrypts` out of the box.

Fix: Identify PII fields (email, phone, payment metadata) and add `encrypts` declarations, with a migration to backfill existing data.

---

## 2. Architecture & Maintainability

### Fat Controllers

The controller layer has grown far beyond its intended role:

| Controller | Lines |
|---|---|
| `menus_controller.rb` | 1,616 |
| `restaurants_controller.rb` | 1,547 |
| `ordrs_controller.rb` | 670 |
| `application_controller.rb` | 532 |
| `smartmenus_controller.rb` | 515 |

`menus_controller.rb` contains inline performance metric collection (calculating memory with `ps`, counting DB connections) — these belong in a service. Several of these methods return hardcoded placeholders that are never populated:

```ruby
def collect_response_time_data
  { average: 250, maximum: 1200, request_count: 0, cache_efficiency: 85.5 }
end
```

Fix: Extract action groups into concerns or sub-controllers (`Menus::VersionsController`, `Menus::LocalizationController`, etc.). Move all metric collection to the existing `PerformanceMetricsService`.

### Inconsistent Naming Conventions

Ruby convention is `snake_case` everywhere. This codebase has a significant number of `camelCase` database column names and methods:

- Columns: `orderedAt`, `displayImages`, `allowOrdering`, `preptime`, `itemtype`
- Methods: `runningTotal`, `grossInCents`, `totalItemsCount`, `genImageId`

This forces quoted column names in raw SQL (e.g. `ordrs."orderedAt"`), creates friction with Rails conventions, and surprises new developers.

Fix: Migrate columns to `snake_case` progressively via migrations with aliases for backward compatibility. Rename Ruby methods to match.

### Duplicate and Redundant Dependencies

```ruby
gem 'openai', '~> 0.25.0'  # these are the same gem
gem 'ruby-openai'
```

Additional redundancies:
- `redis-store` + `redis-activesupport` — both deprecated; the built-in `redis-cache-store` is already configured
- `shrine` + `active_storage` — two file upload systems coexisting
- `madmin` admin UI + custom `admin/` namespace — two admin interfaces
- Four esbuild configs: `esbuild.config.mjs`, `esbuild.final.config.mjs`, `esbuild.optimized.config.mjs`, `esbuild.super-optimized.config.mjs`

Fix: Remove duplicate `ruby-openai` gem. Remove deprecated Redis gems. Choose one file upload library and migrate. Consolidate esbuild configs to one.

### Root Directory Clutter

Files that indicate ad-hoc development committed to the repo:
- `app/models/user.rb.tmp` — leftover temp file
- `fix_response_expectations.rb`, `test_all_controllers.rb`, `test_controller_migration.rb`, `test_nested_routes.rb` — one-off scripts
- `restart.sh`, `scaffolding.sh`, `setup_deepl_credentials.sh` — unversioned operational scripts
- `CASCADE.md`, `PHASE_4_COMPLETION_SUMMARY.md`, `PERFORMANCE_OPTIMIZATIONS.md` — progress notes, not documentation
- `test/skip_problematic_tests.rb` — tests should be fixed, not scripted around

Fix: Delete temp files. Move operational scripts to `bin/`. Archive or remove phase notes.

---

## 3. Testing

### Coverage and Strategy

- 81 model tests for 102 models — 21 models have no tests
- 21 system tests — thin for a customer-facing ordering application
- Two testing frameworks (Minitest + RSpec) — doubles maintenance overhead with no clear ownership boundary
- CI says "Run tests with coverage threshold" but no threshold is enforced — SimpleCov is configured but has no minimum or failure condition

### System Test Infrastructure

`ApplicationSystemTestCase` uses `use_transactional_tests = false` with manual `delete_all_tables_in_fk_order!`. This is slow, fragile, and non-standard. `test/support/test_id_helpers.rb` has grown to 500+ lines managing DOM state from Ruby test code — a sign that production JS is difficult to test in isolation.

Fix:
1. Commit to Minitest and migrate or delete the RSpec specs
2. Enforce a coverage minimum in CI (start at 60%, raise quarterly)
3. Add model tests for all models with business logic
4. Evaluate database_cleaner with truncation strategy

### Test Pollution Artefacts

- `test/LOCALE_SWITCHING_DIAGNOSIS.md`, `test/LOCALE_SWITCHING_TEST_PLAN.md`
- `test/skip_problematic_tests.rb`

These indicate debugging sessions that were committed rather than cleaned up.

---

## 4. Database

### Aggressive `dependent: :delete_all` Usage

`dependent: :delete_all` is used throughout `restaurant.rb`, `menu.rb`, `menuitem.rb`, etc. This bypasses ActiveRecord callbacks, skips validations, and can leave orphaned records. Deleting a restaurant this way skips `after_destroy` callbacks on `Ordr`, potentially orphaning payment records and financial audit trails.

Fix: Audit every `dependent: :delete_all`. Replace with `dependent: :destroy` wherever callbacks matter — specifically any model involved in financial records, file attachments, or audit logs.

### Cache Invalidation Disabled on Ordr

`app/models/ordr.rb:93-95`:
```ruby
# Cache invalidation hooks - DISABLED in favor of background jobs
# after_update :invalidate_order_caches
# after_destroy :invalidate_order_caches
```

Stale order data can be served from cache after updates. The "background job" alternative is not documented or obviously monitored.

Fix: Restore the callbacks using `after_commit` (to avoid rollback issues), or document exactly which job handles invalidation and add monitoring to ensure it runs.

### Caching Layer Complexity

The app runs three caching layers simultaneously:
1. Redis (primary cache store)
2. Memcached/Dalli (for IdentityCache's CAS support)
3. IdentityCache + custom L2 cache

This is complex to reason about, debug, and maintain. Two separate cache invalidation paths exist and their interaction is unclear.

Fix: Evaluate whether IdentityCache's benefits justify the operational complexity. Document the cache hierarchy explicitly. Consider consolidating to Redis + `Rails.cache` with careful `includes`.

### Low Default DB Pool Size

`pool: <%= ENV.fetch("DB_POOL_SIZE", 5).to_i %>` in production. With Puma threads plus Sidekiq workers, 5 connections will exhaust under load.

Fix: Set `DB_POOL_SIZE` default to at least 10. Align with `RAILS_MAX_THREADS` + Sidekiq concurrency.

---

## 5. API Design

### Test Controller Exposed in Production

`app/controllers/api/v1/test_controller.rb` is accessible in production via `GET /api/v1/test/ping`. This is an information disclosure risk at minimum.

Fix: Move behind a `if Rails.env.development? || Rails.env.test?` routing guard (same pattern as Rswag).

### No Versioning or Deprecation Strategy

API v2 exists but only has 2 controllers. There are no `Sunset` or `Deprecation` response headers, no changelog, and no versioning policy document. External API consumers have no way to know what is changing or being retired.

Fix: Document the API versioning policy. Add `Deprecation` and `Sunset` headers (RFC 8594) to v1 endpoints that have v2 equivalents. Define a sunset timeline.

### No Pagination on Collection Endpoints

`GET /api/v1/restaurants` and similar endpoints return all records — unbounded at scale.

Fix: Add cursor or page-based pagination (Pagy is recommended) to all collection endpoints. Document limits in the OpenAPI spec.

---

## 6. Observability & Error Handling

### 178 Bare Rescues in Controllers

The controller layer has 178 instances of `rescue StandardError` or bare `rescue`. Many follow this pattern:

```ruby
rescue StandardError
  nil
end
```

Failures are invisible — no Sentry report, no log line, no metric. The placeholder performance methods in `menus_controller.rb` and `restaurants_controller.rb` return hardcoded zeros and catch all errors, making a real failure indistinguishable from "no data".

Fix: Establish a policy: every `rescue` must either re-raise, log at warn/error level, or report to Sentry via `Sentry.capture_exception(e)`. Remove placeholder metric methods that return hardcoded values.

### Inconsistent Structured Logging

`app/services/structured_logger.rb` exists but controller logging is ad-hoc (`Rails.logger.error "[SmartmenusController#show] ..."` without structured fields). Without consistent fields (user_id, restaurant_id, request_id), log aggregation is difficult.

Fix: Use the existing `StructuredLogger` throughout controllers. Ensure user_id and tenant context is attached to every Sentry event.

---

## 7. CI/CD

### Two Overlapping CI Files

Both `.github/workflows/ci.yml` and `.github/workflows/tests.yml` define a `test` job that runs `bundle exec rails test`. Tests run twice on every push to `main`.

Fix: Consolidate into a single workflow file.

### System Tests Not Run in CI

The CI runs `bundle exec rails test` but system tests require Chrome. The CI does not install a browser, so system tests are silently skipped. Customer-critical ordering flows have no automated CI coverage.

Fix: Add Chrome to the CI test job (`sudo apt-get install -y google-chrome-stable`) and explicitly include system tests, or run them in a dedicated job with a headless browser service.

### No Deployment Automation

The `deploy-check` job verifies readiness but does not deploy. There is no staging deploy on PR merge and no production deploy on main merge — the release process is entirely manual.

Fix: Add a deploy step for a staging environment at minimum. Use Heroku review apps or a branch-based deploy trigger.

---

## Prioritised Remediation Plan

### Phase 1 — Critical (Completed 2026-03-20)

| # | Issue | Effort | Status |
|---|---|---|---|
| 1 | Rotate and remove hardcoded DeepL key | 1h | Done |
| 2 | Fix Rack::Attack to use Redis store | 30m | Done |
| 3 | Remove API test controller from production routing | 30m | Done |
| 4 | Remove duplicate `ruby-openai` gem | 15m | Done |
| 5 | Restore CSRF on `create_version` / `activate_version` | 2h | Done |
| 6 | Uncomment `require_master_key` in production | 15m | Done |

### Phase 2 — High (Completed 2026-03-20)

| # | Issue | Effort | Status |
|---|---|---|---|
| 7 | Make JWT revocation Redis-backed (not Rails.cache) | 1d | Done — `JwtService` now uses a dedicated `Redis.new` connection with `SETEX`/`EXISTS` |
| 8 | Enforce CSP — remove `unsafe_eval`, add report URI, switch to enforce mode | 3d | Partial — `unsafe_eval` removed, report URI added via `CSP_REPORT_URI` env var, mode switched to enforce. `unsafe_inline` remains pending migration of inline scripts to Stimulus. |
| 9 | Fix bare `rescue` blocks to log or report to Sentry | 2d | Done — all 178 instances across 38 controller files now capture `=> e` and log at warn/error level |
| 10 | Consolidate CI workflows into one file | 2h | Done — `tests.yml` deleted; `ci.yml` now triggers on all PRs |
| 11 | Add system tests to CI with Chrome | 1d | Done — Chrome installed and `rails test:system` added to CI test step |
| 12 | Enforce SimpleCov coverage threshold in CI | 2h | Done — `COVERAGE_MIN: 60` added to CI test step env |
| 13 | Remove deprecated `redis-store` / `redis-activesupport` gems | 2h | Done |

### Phase 3 — Medium (Completed 2026-03-20)

| # | Issue | Effort | Status |
|---|---|---|---|
| 14 | Decompose `menus_controller.rb` and `restaurants_controller.rb` | 1w | Done — `menus_controller.rb` decomposed from 1,616 lines into 6 focused sub-controllers under `app/controllers/menus/`. `restaurants_controller.rb` decomposed from 1,547 lines into 7 focused sub-controllers under `app/controllers/restaurants/`: `BaseController` (shared setup), `SpotifyController`, `AlcoholPolicyController`, `LifecycleController` (archive/restore/publish_preview), `AnalyticsController` (deduplicates the two `analytics` methods), `PerformanceController`, `HoursController`. `restaurants_controller.rb` reduced to ~380 lines (CRUD + bulk ops only). Routes updated. |
| 15 | Audit and migrate `dependent: :delete_all` for financial / audit models | 3d | Done — `restaurant→menus`, `restaurant→restaurant_menus`, `menu→menusections`, `menusection→menuitems` changed to `dependent: :destroy` to preserve AR callbacks |
| 16 | Add model tests for the 21 untested models | 1w | Partial — 5 high-priority models covered: `AlcoholPolicy`, `RestaurantSubscription`, `StaffInvitation`, `ProfitMarginTarget`, `MenuVersion`. 16 models remain untested. Remaining candidates: `OrdrStationTicket`, `MenuItemProductLink`, `BeveragePipelineRun`, `PaymentRefund`, `LedgerEvent`, `OrdrSplitPayment`, and others. |
| 17 | Choose and consolidate to one file upload system (Shrine or ActiveStorage) | 1w | Decision made, migration deferred — Shrine handles image derivatives on `Restaurant`, `Menu`, `Menuitem`, `Menusection`; ActiveStorage handles PDFs/audio/avatar on `Menu`, `OcrMenuImport`, `User`, `VoiceCommand`, `MenuSource`. These serve distinct use cases; consolidation deferred pending resource allocation. |
| 18 | Add ActiveRecord Encryption for PII fields | 3d | Done — `user.first_name/last_name`, `employee.name/email` (deterministic), `payment_attempt.provider_checkout_url` encrypted. `support_unencrypted_data = true` set in initializer for migration period. Backfill via `bin/rails pii:encrypt`. `user.email` deferred (Devise + IdentityCache dependency). |
| 19 | Add pagination to API collection endpoints | 2d | Done (pre-existing) — all collection endpoints already use Pagy |
| 20 | Fix DB pool size default to match Puma + Sidekiq concurrency | 30m | Done (pre-existing) — pool default already set to 10 |

### Phase 4 — Long-term (Not Started)

| # | Issue | Effort | Status |
|---|---|---|---|
| 21 | Migrate `camelCase` columns to `snake_case` | 2w | Not started |
| 22 | Define and document API versioning / deprecation strategy | 1w | Not started |
| 23 | Evaluate and simplify caching layer (Redis vs IdentityCache vs L2) | 2w | Not started |
| 24 | Commit to one test framework — remove RSpec or Minitest | 1w | Not started |
| 25 | Add deployment automation (staging deploy on merge) | 3d | Not started |
