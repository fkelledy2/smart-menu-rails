---
name: mellow.menu architectural patterns recurring across feature specs
description: Architectural decisions and patterns that recur across multiple feature specs in the backlog
type: project
---

Patterns observed across the full feature backlog (41 files, March 2026 analysis).

**Why:** These patterns must be respected when writing or reviewing any future spec for mellow.menu. Violations create technical debt and inconsistency.

**How to apply:** Check every new spec against these patterns before finalising technical notes.

## Universal Patterns

- **Business logic in app/services/**: Every feature spec requires one or more service objects. 83 already exist — check for reuse before creating new ones.
- **Heavy/async work in app/jobs/**: Sidekiq jobs with retry logic. All background work routes through jobs, never inline in controllers.
- **Pundit policies for every new model**: Every new model needs a corresponding `app/policies/` file.
- **Flipper feature flags for all new features**: Enable safe rollout per restaurant. Nearly every spec uses a per-restaurant Flipper flag.
- **Payments::Orchestrator always**: Never call Stripe or Square directly. All payment flows (capture, refund, subscription change) route through `Payments::Orchestrator`.
- **Admin tools in Admin:: namespace, never Madmin**: Confirmed explicitly in pricing (#12, #13) and JWT (#8) specs. There is a plan to migrate away from Madmin.
- **Order model spelling**: `Ordr`, `Ordritem`, `Ordrparticipant`, `OrdrAction` — intentional non-standard spelling. Never create `Order` or `OrderItem`.

## Security Patterns
- **DiningSession required for order mutations**: Once QR Security ships, all `POST ordritems` and order mutations require a valid, non-expired DiningSession. New features that create or mutate orders must respect this.
- **Admin access tiers**: `admin?` for general admin area; `admin? && super_admin?` for sensitive cost/pricing/impersonation tooling. Never use `admin?` alone for financial data.
- **Mellow admin by email domain**: Features restricted to mellow.menu staff use `current_user.email.ends_with?('@mellow.menu')` pattern (Pre-configured QRs, JWT management).
- **Rotating public tokens**: Smartmenu public URLs use `/t/:public_token` (64-char hex). The old `/smartmenus/:slug` route remains as a redirect fallback.

## Realtime Patterns
- **ActionCable for realtime updates**: Use existing channels or create new ones (e.g. FloorplanChannel). Stream names follow pattern: `"feature:resource:#{id}"`.
- **Turbo Streams for partial updates**: Broadcast partial re-renders of tiles/components rather than full page reloads.

## API Patterns
- **JWT for third-party API access**: All partner/third-party API access uses JWT tokens managed by the JWT Token Management system (#8).
- **Scope-based access control**: API scopes defined as `resource:action` strings (e.g. `menu:read`, `orders:write`).

## Database Patterns
- **Statement timeouts**: 5s primary DB, 15s replica. Analytics/reporting queries must use the replica.
- **jsonb for flexible data**: Cost inputs, addon metadata, agent capabilities — all use jsonb columns.
- **Idempotency**: Jobs and webhooks must be idempotent. Duplicate executions must not cause double-charges or duplicate records.
