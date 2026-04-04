# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Development
```bash
bin/dev          # Start all processes (web, Sidekiq, esbuild, Sass)
bin/setup        # One-time environment setup
bin/rails server # Start web server only (port 3000)
```

### Testing
```bash
bin/fast_test                    # Run all tests (parallel, fast)
bin/fast_test test/models/foo_test.rb  # Run a single test file
bin/fast_test test/models/foo_test.rb:42  # Run a single test at line
bundle exec rails test           # Standard test runner
ENABLE_COVERAGE=true bin/fast_test  # With coverage report
bin/rails db:test:prepare        # Reset test database
```

### Linting
```bash
bundle exec rubocop              # Ruby linting
bundle exec rubocop -a           # Auto-fix Ruby
bundle exec brakeman             # Security scan
yarn lint                        # All JS/CSS linting
yarn lint:fix                    # Auto-fix JS/CSS
yarn lint:js / yarn lint:css     # Individual linters
```

### Documentation
```bash
bin/generate_docs  # Regenerate docs/ARCHITECTURE.md, DATA_MODEL.md, SERVICE_MAP.md
```

## Architecture

**Smart Menu** is a multi-tenant SaaS restaurant management and ordering platform. Each `Restaurant` is the primary tenant. Core flow: Restaurants have Menus → MenuSections → MenuItems. Customers place Ordrs containing Ordritems, with optional Ordrparticipants for bill-splitting.

### Stack
- **Rails 7.2** / Ruby 3.3 / PostgreSQL 14+ (with pgvector)
- **Frontend**: Hotwire (Turbo + Stimulus), Bootstrap 5, esbuild + Sass
- **Auth**: Devise 5 + Pundit (48 policies), OmniAuth (Google, Apple, Spotify)
- **Background jobs**: Sidekiq + Redis
- **Realtime**: ActionCable (Redis adapter)
- **Caching**: Memcached (Dalli) + IdentityCache + Redis
- **Payments**: Stripe + Square via adapter pattern (`Payments::Orchestrator`)
- **AI/ML**: OpenAI (GPT-4o, DALL-E), Google Cloud Vision (OCR), pgvector embeddings
- **Feature flags**: Flipper

### Key Directories
- `app/services/` — 83 service objects for business logic (keep controllers thin)
- `app/jobs/` — 53 Sidekiq background jobs
- `app/policies/` — Pundit authorization (one policy per model)
- `app/channels/` — 6 ActionCable channels for realtime updates
- `app/components/` — ViewComponent reusable UI components
- `docs/` — Auto-generated architecture/model/service docs (do not edit manually)

### Payment Architecture
Dual-provider system with `Payments::Orchestrator` routing to Stripe or Square adapters. Webhooks handled by `Payments::Webhooks::StripeIngestor` and `SquareIngestor`. Financial records tracked via `Payments::Ledger`.

### Database
Multi-database setup with primary + read replica. Analytics queries use the replica. Key extensions: pgvector (embeddings), full-text search. Materialized views (e.g., `dw_orders_mv`) for reporting. Statement timeout: 5s primary, 15s replica.

### Order Naming Conventions
Order-related models use intentional non-standard spelling: `Ordr`, `Ordritem`, `Ordrparticipant`, `OrdrAction`, `OdrSplitPayment` — this is deliberate, not a typo.

### Menu Features
- Versioning with diff support
- 40+ language localization via DeepL
- AI image generation (DALL-E)
- OCR import from photos/PDFs (Google Cloud Vision)
- Profit margin tracking and AI-powered optimization (pricing, bundling, engineering)

### Admin & Ops
- `admin/` namespace for internal tools (restaurant discovery, menu source reviews)
- Sidekiq UI at `/sidekiq` (admin-protected)
- Flipper UI for feature flag management
- Pretender gem for admin impersonation (with `ImpersonationAudit` logging)
- RackAttack for rate limiting

### RuboCop Style
Single quotes preferred. Trailing commas enforced. Migrations, bin, config, and routes are excluded from linting. Target Ruby 3.3.

### Stimulus Controllers — Asset Manifest (IMPORTANT)
Every new Stimulus controller file in `app/javascript/controllers/` **must** also be declared in `app/assets/config/manifest.js`, or it will fail in production with:

```
Asset `controllers/foo_controller.js` was not declared to be precompiled in production.
```

This is NOT caught by RuboCop, the test suite, or CI. You must add it manually every time.

Pattern — add one line to `app/assets/config/manifest.js`:
```
//= link controllers/foo_controller.js
```

And register it in `app/javascript/controllers/index.js`:
```js
import FooController from './foo_controller'
application.register('foo', FooController)
```

Both files must be updated together whenever a new controller is created.
