# Smart Menu — Cascade Core Rules

## Identity
Multi-tenant SaaS restaurant management platform.

One User can belong to many Restaurants.

Deployment target: Heroku.

Core infrastructure:
- PostgreSQL
- Redis
- Memcached

---

## Tech Stack

Backend
- Ruby 3.3.10
- Rails 7.2.2
- PostgreSQL 14+

Frontend
- Hotwire (Turbo + Stimulus)
- importmap-rails
- esbuild
- SCSS via cssbundling-rails

Infrastructure
- Sidekiq 7 (Redis)
- ActionCable (Redis)
- Memcached via Dalli / IdentityCache

Auth / Access
- Devise
- OmniAuth (Google / Apple / Spotify)
- Pundit
- Flipper feature flags

Payments
- Stripe
- Square REST v2

AI / Data
- OpenAI (GPT-4o, DALL-E)
- Google Cloud Vision
- DeepL

Storage
- Shrine
- ActiveStorage
- AWS S3

Monitoring
- Sentry

---

# Canonical Non-Standard Naming

This application intentionally uses non-standard Rails names.

Never guess Rails defaults.

| Domain | Model | Table |
|------|------|------|
Order | `Ordr` | `ordrs`
Order Item | `Ordritem` | `ordritems`
Order Item Note | `Ordritemnote` | `ordritemnotes`
Order Participant | `Ordrparticipant` | `ordrparticipants`
Order Action | `Ordraction` | `ordractions`
Menu Section | `Menusection` | `menusections`
Menu Item | `Menuitem` | `menuitems`
Menu Participant | `Menuparticipant` | `menuparticipants`
Restaurant Table | `Tablesetting` | `tablesettings`
Allergen | `Allergyn` | `allergyns`

Additional invariants:

- Ordritem price column = `ordritemprice`
- Status fields use integer enums

Example:

opened: 0
ordered: 20
preparing: 22
ready: 24
delivered: 25
billrequested: 30
paid: 35
closed: 40

---

# Source of Truth

Routes / path helpers  
config/routes.rb

Database schema  
db/schema.rb

Runtime behaviour  
Code takes precedence over documentation.

Order projection  
app/services/order_event_projector.rb

Smartmenu state  
app/presenters/smartmenu_state.rb

Payment settlement truth  
Payment webhooks + payment records

---

# Key Entry Points

Customer Smart Menu  
app/views/smartmenus/show.html.erb

Customer ordering JS  
app/javascript/ordr_commons.js

Central state manager  
app/javascript/controllers/state_controller.js

Staff ordering  
app/javascript/ordrs.js

Order items controller  
app/controllers/ordritems_controller.rb

Payments  
app/controllers/ordr_payments_controller.rb

Realtime state  
app/presenters/smartmenu_state.rb

---

# Context Discipline

Do NOT scan the whole repository.

Read only files directly relevant to the task.

Preferred workflow:

1. Identify entry point
2. Inspect local code
3. Expand outward only if necessary

Prefer targeted search over broad directory reads.

---

# Retrieval Discipline

Use these references when required:

Routes  
config/routes.rb

Schema / tables  
db/schema.rb

Architecture  
docs/ARCHITECTURE.md

Data model  
docs/DATA_MODEL.md

Ownership / call sites  
docs/SERVICE_MAP.md

Always read the minimum required context.

---

# Code Style

Follow existing patterns in nearby files.

Rules:

- Do not add or remove comments unless requested
- ERB partials use underscore prefix
- Prefer locals over instance variables in partials
- Stimulus controllers use kebab-case filenames
- Services live in app/services
- Background jobs live in app/jobs

Jobs enqueue using:

.perform_later

---

# Testing

Prefer focused tests.

Minitest
bin/rails test

RSpec
bundle exec rspec

System tests
bin/rails test:system

---

# Known Pitfalls

Precompiled assets in public/assets/ may override development source files.
Delete if JS changes do not appear.

API controllers may need to skip web callbacks.

Menu model conflicts with Menu:: namespace.
Correct pattern:

class Menu::MyJob

Do not assume route helpers.
Always verify in config/routes.rb

AdvancedCacheService returns Hash objects, not ActiveRecord models.
Requery using .where(id:) if model methods are required.

---

# Indexing Exclusions

Never index or search these unless explicitly required:

.git
node_modules
tmp
log
coverage
storage
public/assets
public/packs
public/packs-test
vendor/bundle
vendor/cache
.bundle
.idea
.snapshots
backup
.sass-cache
db/migrate

Also ignore:

*.log
*.pid
*.tmp
coverage/**
tmp/**


