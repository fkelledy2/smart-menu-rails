# Architecture Overview

> **Auto-generated** by `bin/generate_docs` on 2026-03-05 23:30 UTC

---

## 1. Technology Stack

| Layer | Technology | Version |
|---|---|---|
| **Language** | Ruby | 3.3.10 |
| **Framework** | Ruby on Rails | 7.2.2 |
| **Database** | PostgreSQL | 14+ (with `pgvector` extension) |
| **Cache** | Memcached (Dalli) + Redis | Dalli 3.x, Redis for Sidekiq/ActionCable |
| **Background Jobs** | Sidekiq | 7.x |
| **WebSockets** | ActionCable | Redis adapter |
| **Web Server** | Puma | 7.x |
| **JS Bundling** | esbuild + importmap-rails | — |
| **CSS Bundling** | cssbundling-rails (Sass + PostCSS) | — |
| **Frontend** | Hotwire (Turbo + Stimulus) | — |
| **Auth** | Devise + OmniAuth | Google, Apple, Spotify |
| **Authorization** | Pundit | 2.x |
| **Feature Flags** | Flipper (ActiveRecord backend) | 1.3.x |
| **Payments** | Stripe + Square | Stripe 13.x, Square REST v2 |
| **File Uploads** | Shrine + Active Storage | — |
| **Search** | PostgreSQL full-text + pgvector | — |
| **AI / ML** | OpenAI (GPT-4o, DALL-E, Whisper) | ruby-openai gem |
| **Vision OCR** | Google Cloud Vision | 2.x |
| **Translation** | DeepL API | — |
| **Monitoring** | Sentry | 5.12.x |

---

## 2. High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        CLIENTS                                  │
│  Browser (Turbo/Stimulus)  │  Mobile (PWA)  │  API consumers   │
└────────────┬───────────────┴────────┬───────┴────────┬─────────┘
             │ HTTPS                  │ WSS            │ JSON
             ▼                        ▼                ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Heroku / Puma                                │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────────────────┐ │
│  │ Web (MVC)    │  │ ActionCable  │  │ API v1 / v2 (JSON)    │ │
│  │ Controllers  │  │ Channels     │  │ BaseController         │ │
│  └──────┬───────┘  └──────┬───────┘  └───────────┬────────────┘ │
│         │                 │                      │              │
│  ┌──────▼─────────────────▼──────────────────────▼────────────┐ │
│  │              Service Layer (app/services/)                 │ │
│  │  Payments │ Menu Discovery │ Beverage Intelligence │ etc.  │ │
│  └──────┬─────────────────────────────────────────────────────┘ │
│         │                                                       │
│  ┌──────▼─────────────────────────────────────────────────────┐ │
│  │              Models (app/models/) + Policies (Pundit)      │ │
│  └──────┬─────────────────────────────────────────────────────┘ │
└─────────┼───────────────────────────────────────────────────────┘
          │
    ┌─────▼──────┐   ┌───────────┐   ┌────────────┐   ┌──────────┐
    │ PostgreSQL │   │   Redis   │   │ Memcached  │   │  S3/CDN  │
    │ (primary + │   │ (Sidekiq  │   │ (Identity  │   │ (Shrine  │
    │  replica)  │   │  + Cable) │   │  Cache)    │   │  uploads)│
    └────────────┘   └───────────┘   └────────────┘   └──────────┘
```

---

## 3. Codebase Statistics

| Component | Count |
|---|---|
| **Models** | 95 |
| **Controllers** (total) | 123 |
| — Admin controllers | 14 |
| — API v1 endpoints | 9 |
| — API v2 endpoints | 2 |
| — Payment controllers | 9 |
| **Service objects** | 83 |
| **Background jobs** | 53 |
| **Pundit policies** | 48 |
| **ActionCable channels** | 6 |
| **Stimulus controllers** | -2 |
| **ERB views** | 386 |
| **Rack middleware** | 3 |
| **Database tables** | 105 |

---

## 4. Directory Structure

```
app/
├── assets/             # Stylesheets (SCSS), static images
├── channels/           # ActionCable channels (6)
├── components/         # ViewComponent classes
├── controllers/        # MVC controllers
│   ├── admin/          #   Admin-only controllers (14)
│   ├── api/v1/         #   REST API v1 (9 endpoints)
│   ├── api/v2/         #   REST API v2 (2 endpoints)
│   ├── payments/       #   Payment-specific controllers (9)
│   └── concerns/       #   Shared controller concerns
├── helpers/            # View helpers
├── javascript/         # JS source (esbuild entry points + Stimulus)
│   ├── controllers/    #   Stimulus controllers (-2)
│   ├── channels/       #   ActionCable JS subscribers
│   ├── modules/        #   Shared JS modules
│   └── utils/          #   JS utility functions
├── jobs/               # Sidekiq background jobs (53)
├── mailers/            # ActionMailer classes
├── middleware/          # Rack middleware (3)
├── models/             # ActiveRecord models (95)
├── policies/           # Pundit authorization policies (48)
├── services/           # Business logic service objects (83)
│   ├── beverage_intelligence/  # Flavor profiling, pairing engine
│   ├── google_places/          # Places API integration
│   ├── menu_discovery/         # Web scraping, menu extraction
│   └── payments/               # Payment orchestration
└── views/              # ERB templates (386)
config/
├── database.yml        # Multi-database (primary + replica)
├── routes.rb           # All route definitions
├── initializers/       # Rails initializers
└── locales/            # I18n translation files
db/
├── schema.rb           # Current schema (105 tables)
└── migrate/            # All migrations
```

---

## 5. Request Flow

### 5.1 Web Request (HTML)

1. **Puma** accepts HTTP request
2. **Rack middleware** stack: `RackAttack` → `MetricsMiddleware` → `RequestLoggingMiddleware`
3. **Router** dispatches to controller
4. **ApplicationController** runs `before_action` chain: `authenticate_user!` → `set_current_employee` → `set_permissions` → `switch_locale`
5. **Controller** action calls service objects, queries models
6. **Pundit** `authorize` checks policy
7. **View** renders ERB with Turbo Frames/Streams

### 5.2 API Request (JSON)

1. Request hits `/api/v1/...` or `/api/v2/...`
2. `Api::V1::BaseController` skips web-specific callbacks
3. JWT authentication via `JwtService`
4. JSON response via `jbuilder` or `render json:`

### 5.3 WebSocket (ActionCable)

1. Client connects via `ws://` / `wss://`
2. **Redis** adapter manages pub/sub
3. Server-side broadcasts triggered by model callbacks or service objects

### 5.4 Background Job

1. Controller or service enqueues job via `MyJob.perform_later`
2. **Sidekiq** picks job from **Redis** queue
3. Job executes and persists results / broadcasts via ActionCable

---

## 6. Payment Architecture

Dual-provider payment system supporting **Stripe** and **Square**.

```
                    ┌─────────────────┐
                    │  Orchestrator   │
                    └───────┬─────────┘
                ┌───────────┴───────────┐
                ▼                       ▼
    ┌───────────────────┐   ┌───────────────────┐
    │  StripeAdapter    │   │  SquareAdapter     │
    └───────────────────┘   └───────────────────┘
                │                       │
                ▼                       ▼
    ┌───────────────────┐   ┌───────────────────┐
    │ StripeIngestor    │   │ SquareIngestor     │
    │ (webhooks)        │   │ (webhooks)         │
    └───────────────────┘   └───────────────────┘
```

---

## 7. Authentication & Authorization

| Concern | Solution |
|---|---|---|
| **User auth** | Devise (email/password, confirmable, lockable) |
| **Social auth** | OmniAuth (Google, Apple, Spotify) |
| **Admin impersonation** | Pretender gem + `ImpersonationAudit` |
| **Authorization** | Pundit policies (48 policy classes) |
| **API auth** | JWT tokens via `JwtService` |
| **Feature flags** | Flipper (per-user, per-restaurant toggles) |

---

## 8. External Integrations

| Service | Purpose |
|---|---|
| **Stripe** | SaaS subscriptions + customer payments |
| **Square** | Customer payments (inline + hosted) |
| **OpenAI** | Menu polishing, image gen, price inference |
| **Google Cloud Vision** | Menu OCR from photos/PDFs |
| **Google Places** | Restaurant discovery, address resolution |
| **DeepL** | Menu translation (40+ languages) |
| **Spotify** | Restaurant playlist sync |
| **Segment** | Product analytics |
| **Sentry** | Error tracking |
| **AWS S3** | File storage (Shrine uploads) |

---

## 9. Caching Strategy

| Layer | Technology | Purpose |
|---|---|---|
| **L1** | Memcached (Dalli) | Model-level IdentityCache |
| **L2** | Redis | Query result caching |
| **L3** | Rails cache (Memcached) | View fragment caching |
| **Warming** | `CacheWarmingJob` | Predictive warming |
| **Invalidation** | `CacheInvalidationJob` | Dependency-graph-aware |
