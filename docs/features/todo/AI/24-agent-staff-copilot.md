# Staff Copilot Agent

## Status
- Priority Rank: #24 (Phase 2 agent — most complex UX integration; ship after back-office agent patterns are proven by Growth Digest and Optimization agents)
- Category: Post-Launch — agent tier, Phase 2
- Effort: L
- Dependencies: Agent Framework (#17), back-office controllers and service objects (existing), `RestaurantInsightsService` (existing), `ProfitMarginAnalyticsService` (existing), OpenAI API with streaming

## Problem Statement
Restaurant managers spend a disproportionate amount of time on routine back-office tasks that require navigating multiple screens, running reports manually, and making the same configuration changes repeatedly. A manager who wants to 86 an item during service must navigate three screens. Pulling a weekly margin report requires knowledge of which analytics page to use and how to interpret it. Drafting a team briefing note before a shift requires starting from scratch in a text editor. These tasks are individually small but collectively consume significant management time — time that could be spent on the floor serving customers. The Staff Copilot adds a natural-language interface to the existing back office, allowing managers and waiting staff to complete routine tasks by describing what they want in plain language and confirming a single proposed action, rather than navigating multiple UI screens. It is a productivity layer on top of the existing product — not a replacement for it.

## Success Criteria
- Managers can complete at least 5 routine back-office tasks via the copilot within 60 seconds each (baseline: equivalent manual navigation time).
- Copilot weekly adoption rate reaches 30% of active managers within 2 months of launch.
- The confirm rate on proposed actions exceeds 65% (measures whether the agent is proposing the right thing, not just any thing).
- The copilot never executes any write action without an explicit manager confirmation step — verified by end-to-end tests.
- The copilot works on mobile (managers frequently use back office on phone during service).

## User Stories
- As a restaurant manager, I want to type "86 the burrata" and confirm a single action to remove it from the live menu, instead of navigating three screens during busy service.
- As a restaurant manager, I want to type "show me last week's best sellers by margin" and receive a formatted table instantly, without navigating to the analytics dashboard.
- As a manager, I want to type "add a new special: Grilled Salmon €28, contains fish and gluten" and confirm the item creation, so I can update the menu in seconds during a shift.
- As a restaurant owner, I want to draft a team briefing via the copilot and review it before sending, so communications are faster to produce and still under my control.
- As a waiter, I want to type "flag the ribeye — running low" and confirm a stock alert, so the kitchen is notified without me leaving the floor to find a manager.

## Functional Requirements

1. The copilot is a persistent UI element in the back office — a collapsible input bar in the sidebar or bottom navigation. Collapsed by default; expanded when staff clicks/taps it.
2. Staff types a natural language request. The request is submitted to `POST /restaurants/:id/copilot/query`. The copilot responds via Turbo Stream with a streaming response (visible tokens start within 800ms).
3. `Agents::StaffCopilotService` (synchronous, not a background job for simple queries) handles the request:
   a. Classifies the intent: `analytics_query`, `menu_edit`, `item_availability`, `new_item`, `staff_message`, `report_request`, `unknown`.
   b. Reads page context from the request (which back-office page the manager is currently on).
   c. Calls the appropriate tool(s) from `Agents::Toolbox`.
   d. Returns a structured action card or an inline narrative response.
4. **Analytics queries** (read-only): the copilot fetches data from `RestaurantInsightsService`, `ProfitMarginAnalyticsService`, or `AnalyticsService` and formats the result as a table or summary narrative. No approval gate for read-only queries.
5. **Write actions** (menu edits, item availability, new item, item deletion): the copilot proposes the action as a structured card showing: what will change, a "Confirm" button, and a "Cancel" button. The confirm button submits the action to the appropriate existing service object. The copilot never writes directly to the database — all writes go through the existing service layer.
6. **Item availability toggle** ("86 the burrata"): proposes setting `Menuitem#available: false` on the matched item. Requires staff role or manager role. On confirm, calls `flag_item_unavailable` tool.
7. **New item creation** ("add a new special: Grilled Salmon €28, contains fish and gluten"): parses the natural language into a structured `Menuitem` attribute hash (name, price, allergens, description), shows a preview card, and on confirm calls the existing menuitem creation service.
8. **Staff message draft** ("draft an update for the team about the new menu"): generates a message draft via `draft_staff_message` tool. The manager sees the draft with an edit field and a "Send" button. Sending uses existing notification mailer infrastructure. Never sent without manager review.
9. **Short session history**: the copilot retains the last 5 turns of conversation in the browser session for follow-up questions. Session history is not persisted server-side — it is held in the Stimulus controller's state and passed as context on each request.
10. **Context awareness**: the request payload includes the current back-office page path. The copilot uses this to provide contextually relevant responses (e.g. on the menu editor page, it assumes menu-related intent by default).
11. **Unknown intent handling**: if the copilot cannot classify the intent or map it to a tool, it responds with a clear "I can help with: menu changes, availability, analytics reports, and team messages. What would you like to do?" rather than attempting a hallucinated action.
12. **Mobile support**: the copilot input collapses to a compact floating bar on mobile. Action cards use a full-width layout on small screens. All Stimulus controller logic must work on touch devices.
13. Copilot interactions are logged as lightweight `AgentWorkflowRun` records (type: `staff_copilot`) for adoption analytics. Log: intent_type, tool_called, confirm_or_dismiss, duration_ms.

## Non-Functional Requirements
- First visible response token: under 800ms.
- Full response (for analytics queries and short actions): under 2 seconds.
- Streaming via server-sent events (SSE) or Turbo Stream morphing — not polling.
- The copilot service must not hold a Puma thread for longer than 5 seconds. For complex or slow queries, respond with a "working on it" indicator and stream the result when ready.
- Rate limiting: max 30 copilot queries per back-office session per hour per user. Return 429 with a friendly message if exceeded. Redis counter.
- No write action may be executed without a confirm interaction from the authenticated user. Enforced at the service layer, not just the UI.
- The copilot must be aware of Pundit policy: it must not propose actions the current user's role does not permit. A waiter should not be able to trigger a price change even if they phrase a request for one.
- Flipper flag `agent_staff_copilot` must be enabled per restaurant.

## Technical Notes

### New Service (`app/services/agents/`)
- `agents/staff_copilot_service.rb` — synchronous. Receives: `restaurant_id`, `user_id`, `query_text`, `conversation_history` (array, max 5 turns), `page_context` (string: current path). Returns: a `CopilotResponse` value object with `response_type` (narrative / action_card / error), `narrative_text`, and `action_card` (nil or structured hash with `preview`, `confirm_params`, `tool_name`).

### New Controller
- `app/controllers/restaurants/copilot_controller.rb`
- Route: `POST /restaurants/:id/copilot/query`
- Pundit authorised: `CopilotPolicy#query?` — any restaurant user (owner / manager / staff) can query; write-action proposals are further constrained by the tool's internal Pundit check.
- Streams response via Turbo Streams or SSE.

### New Stimulus Controller
- `app/javascript/controllers/staff_copilot_controller.js` — manages: expand/collapse state, query submission, streaming response rendering, session history management (in-memory, not persisted), action card confirm/cancel handling.

### New Tool
- `tools/read_order_analytics.rb` — queries order history, ticket size, cover count, and margins for the restaurant over a specified period. Uses replica DB. Returns structured hash suitable for table formatting.
- `tools/draft_staff_message.rb` — OpenAI call to compose an internal team briefing. Input: restaurant context, topic, tone. Output: message subject + body string.

### Existing Tools Used
- `read_restaurant_context`
- `search_menu_items`
- `propose_menu_patch` — used for item edits; writes action card payload rather than directly to artifact
- `flag_item_unavailable` — with `confirmed: true` required (same safety pattern as Service Operations agent)
- `compose_manager_summary` — for analytics narrative responses

### Pundit Policy
- `app/policies/copilot_policy.rb` — `query?` returns true for any authenticated restaurant user. Individual tool invocations check the same Pundit policies as their underlying service objects (e.g. menuitem edit checks `MenuitemPolicy#update?`).

### Write Action Safety Pattern
All write actions follow this flow:
1. Copilot parses intent and selects tool.
2. Tool generates an `action_card` with a preview and `confirm_params`.
3. The action card is returned to the browser and displayed with "Confirm" / "Cancel" buttons.
4. On "Confirm", the browser sends a second request to `POST /restaurants/:id/copilot/confirm` with the `confirm_params`.
5. The confirm endpoint validates the action against Pundit, then calls the existing service object.
6. The confirm endpoint never accepts raw SQL or arbitrary method calls — only pre-registered `tool_name` + validated `confirm_params`.

### Flipper Flags
- `agent_framework` (required)
- `agent_staff_copilot`

## Acceptance Criteria
1. A manager types "86 the burrata" and receives an action card showing "Set Burrata as unavailable — Confirm / Cancel" within 800ms. Clicking Confirm sets `Menuitem#available: false` via the existing service layer. No change occurs if the manager clicks Cancel.
2. A manager types "show me last week's best sellers by margin" and receives a formatted table of items ranked by margin contribution within 2 seconds. No confirmation step is required for read-only queries.
3. A manager types "add a new special: Grilled Salmon €28, contains fish and gluten" and receives a preview card with all parsed fields visible. Clicking Confirm creates the `Menuitem` via the existing creation service. The created item has the correct allergen associations.
4. A waiter (non-manager role) typing "change the salmon price to €32" receives a "You don't have permission to change item prices" response and no price change action is created.
5. The confirm endpoint rejects any `tool_name` not in the registered `Agents::Toolbox` list — returns 422.
6. The copilot's session history (5 turns) allows a follow-up like "also flag the truffle pasta as low stock" after a prior 86 action to be correctly interpreted as a separate `flag_item_unavailable` action, not a modification of the previous one.
7. On mobile (375px viewport), the copilot input collapses to a floating bar, action cards render full-width, and all interactions work via touch.
8. 31 queries from the same user in one hour returns a 429 response with a friendly message on the 31st request.
9. An `AgentWorkflowRun` record (type: `staff_copilot`) is created for each query, logging intent_type, tool_called, and confirm_or_dismiss status.
10. With `agent_staff_copilot` flag disabled for a restaurant, the copilot entry point is not rendered in the back-office layout and the query endpoint returns 404.

## Out of Scope
- Persistent chat history across sessions (each session is ephemeral — history is in browser memory only).
- Voice input for the copilot query.
- Copilot access from the customer-facing SmartMenu (back-office staff only).
- Scheduling or labour management integration.
- Integration with external communication tools (Slack, WhatsApp) in v1 — team message drafts are sent via existing in-app mailer only.
- Fully autonomous execution of any action without a confirm step — this is permanently out of scope.

## Open Questions
1. Should waiters have access to the copilot, or is it manager/owner only? The spec assumes waiters can use it for limited actions (availability flags, stock signals) but not for menu edits or pricing. Confirm the role boundary.
2. How should the copilot handle ambiguous item names? If the manager types "86 the chicken" and there are three chicken dishes, the copilot must clarify which one — show a disambiguation card. Confirm this interaction pattern is acceptable and budget the UX work accordingly.
3. Should the confirm endpoint be a separate route (`/copilot/confirm`) or should confirmation be handled client-side by re-submitting the original query with a `confirmed: true` flag? The separate endpoint is cleaner and easier to audit — but needs a decision.
4. Is there an existing staff briefing / internal messaging system that the `draft_staff_message` tool should integrate with, or does this require a new simple message delivery mechanism?
