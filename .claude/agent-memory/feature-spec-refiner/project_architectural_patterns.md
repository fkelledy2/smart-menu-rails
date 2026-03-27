---
name: mellow.menu architectural patterns recurring across feature specs
description: Architectural decisions and patterns that recur across multiple feature specs in the backlog, updated to include AI agent tier patterns
type: project
---

Patterns observed across the full feature backlog (32 ranked features + 2 in-progress items, 50+ files, March 2026 analysis — updated 2026-03-27 fourth pass).

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
- **Existing ActionCable channels**: kitchen_channel, menu_editing_channel, ordr_channel, presence_channel, station_channel, user_channel — check before creating new ones.

## API Patterns
- **JWT for third-party API access**: All partner/third-party API access uses JWT tokens managed by the JWT Token Management system (#8).
- **Scope-based access control**: API scopes defined as `resource:action` strings (e.g. `menu:read`, `orders:write`).

## Database Patterns
- **Statement timeouts**: 5s primary DB, 15s replica. Analytics/reporting queries must use the replica.
- **jsonb for flexible data**: Cost inputs, addon metadata, agent capabilities, workflow step state — all use jsonb columns.
- **Idempotency**: Jobs and webhooks must be idempotent. Duplicate executions must not cause double-charges or duplicate records. Use idempotency_key columns where needed.

## AI Agent Tier Patterns (added 2026-03-24)

- **Agent Framework is a prerequisite**: No individual agent ships before `app/services/agents/` framework services (Dispatcher, Runner, Toolbox, PolicyEvaluator, ArtifactWriter, ApprovalRouter) are in place.
- **agent_framework Flipper flag**: Master switch for all agent work. Must be enabled per restaurant before any workflow runs. Every individual agent also has its own flag (e.g. agent_menu_import, agent_growth_digest).
- **Agents never write to live data directly**: All agent writes go through `Agents::ArtifactWriter` which writes to `AgentArtifact`. Promotion to live records only happens after policy approval and through existing service objects — never direct SQL or bypassing controllers.
- **Policy gate is non-negotiable**: Every write action goes through `Agents::PolicyEvaluator`. The result is auto_approve, require_approval, or blocked. There is no path to bypass this gate.
- **Agent Sidekiq queues**: Five queues with strict priority — agent_critical > agent_realtime > agent_high > agent_default > agent_low. Service Operations uses agent_realtime; Growth Digest uses agent_default; Reputation/Import use agent_high.
- **No agent work in web requests**: Background agents run on worker dynos via Sidekiq. The only exceptions are the Customer Concierge (#18) and Staff Copilot (#22), which are synchronous request-response services (not background jobs) — but they must not hold Puma threads beyond 5 seconds.
- **Streaming LLM responses for customer-facing agents**: The Customer Concierge (#18) and Staff Copilot (#22) must stream LLM output to the browser. Target: first visible token < 800ms.
- **Rule-based fast paths before LLM**: For deterministic signals (queue depth thresholds, stock levels), use rule-based logic. Reserve LLM calls for ambiguous reasoning. This applies especially to Service Operations Agent (#20).
- **Tool objects in app/services/agents/tools/**: Each tool wraps an existing service object. Tools are registered in Agents::Toolbox. Tools do not contain business logic — they delegate to existing services.
- **ToolInvocationLog for every tool call**: Every call to a tool through the Toolbox creates a ToolInvocationLog record. No silent tool mutations.
- **OpenAI via openai_client.rb extension**: The existing openai_client.rb is extended to support the Responses API / tool-use format. Do not create a parallel OpenAI client.
- **No DB transactions spanning LLM calls**: Fetch step → LLM reason step → write step are separate AgentWorkflowStep records. Never open a transaction before an LLM call and commit it after.
- **Domain events via AgentDomainEvent table**: Events are written to the agent_domain_events table (with idempotency_key). Agents::Dispatcher polls this table — it does not use LISTEN/NOTIFY (incompatible with PgBouncer).
- **Allergen enforcement at tool level, not LLM level**: In the Customer Concierge, allergen filters are applied by the search_menu_items tool in Ruby/SQL before the item list reaches the LLM. The LLM is never trusted for allergen safety.
- **GDPR pre-development gate for #18**: Customer dietary preference data passing to OpenAI requires legal sign-off before the Customer Concierge goes live. This is a hard pre-development gate.

## New Patterns From March 2026 Second-Pass Specs

- **Roles on Employee, not User**: Role enums (`staff/manager/admin`) live on `Employee`, scoped per restaurant. `User` has no role column. One user can be admin at restaurant A and staff at restaurant B. Any spec proposing role columns on `User` must be corrected.
- **Third-party payment adapters always via Orchestrator**: When adding new payment-adjacent providers (Strikepay, StrikePay, etc.), create a `Payments::XxxAdapter` and route through `Payments::Orchestrator`. Never call a payment API directly from a controller, model, or arbitrary service.
- **Stimulus controller wraps external map/widget SDKs**: When integrating third-party JS SDKs (map providers, widget libraries), wrap them in a Stimulus controller loaded lazily in `connect()`. No React, no standalone JS components.
- **Existing models as extension points, not replacements**: New features build on existing models where possible. `StaffInvitation` is extended for bulk invites (not replaced). `Employee` role enum is the source of truth for role promotion (not a new `RolePermission` table). Check for existing models before proposing new ones.
- **Append-only audit tables**: Audit/history tables (`EmployeeRoleAudit`, `ImpersonationAudit`) are append-only. Pundit policies must block `update?` and `destroy?`. No `updated_at` column.
- **Marketing documents are not dev specs**: Files describing landing page strategies, SEO agency analyses, competitor research, and content marketing are reference/strategy documents. They are classified with a Disposition header and do not generate engineering tickets directly. The engineering tickets they imply (if any) are captured as small feature specs or in the Gap Analysis section of PRIORITY_INDEX.
