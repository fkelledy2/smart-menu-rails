---
name: Customer Concierge Agent v1 (#20)
description: Key decisions, gotchas, and architecture for the Customer Concierge Agent implementation (April 2026)
type: project
---

Customer Concierge Agent (#20) COMPLETED 2026-04-01.

Synchronous (no Sidekiq job) natural-language menu discovery panel for the customer SmartMenu.
Flipper flags: `agent_framework` (master) + `agent_customer_concierge` (per-restaurant actor).

**Key architecture decisions:**
- Service: `Agents::CustomerConciergeService` — synchronous, not a background job
- 3 new tools: `ReadCustomerPreferences`, `ComposeRecommendation`, `ProposeBasket`
- `SearchMenuItems` extended with `exclude_allergyn_ids` — allergen exclusion enforced in SQL before LLM sees items
- Controller: `Smartmenus::ConciergeController` (not a nested resource — public endpoint, skip auth)
- Route: `POST /t/:public_token/concierge/query`
- Stimulus: `concierge_controller.js` — open/close panel, fetch, render item cards + basket preview
- Caching: `concierge:<restaurant_id>:<MD5(query)>:<menu_version_id>:<allergen_ids>`, 15min TTL

**Gotchas discovered:**
- `Menuitem` table is named `menuitems` (not `menu_items`), association is `menusection` (not `menu_section`), FK column is `menusection_id`. The pre-existing SearchMenuItems tool had wrong table/association names.
- `AgentWorkflowRun` tables live only in migrations (not in `db/schema.rb` — schema may be from before agent migrations ran in test). Test env purges and reloads schema, so agent tables exist in tests.
- `Ordr` uses `tablesetting_id` (not `smartmenu_id`). To find ordrparticipants for a session scoped to a smartmenu, join: `Ordrparticipant → Ordr → Tablesetting → restaurant_id`.
- Concierge JS controller must be declared in `app/assets/config/manifest.js` (asset pipeline precompile list) — same pattern as all other Stimulus controllers.
- `ComposeRecommendation` rescues errors and returns `{ error:, items: [] }` — the calling service must check `result[:error].present?` explicitly before treating the result as success.

**Why:** Line 39-53 of spec: "first visible token < 800ms", synchronous SSE, allergen non-negotiable, no background jobs.

**How to apply:** When building further customer-facing agent features, follow the synchronous service pattern over background jobs. Always enforce content safety (allergens, permissions) in Ruby/SQL before passing data to the LLM.
