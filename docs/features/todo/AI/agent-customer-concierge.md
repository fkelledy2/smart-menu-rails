# Customer Dietary & Ordering Concierge Agent

## Status
- Priority Rank: #19 (Phase 1 agent — high differentiation value; ship after Framework + at least one back-office agent proves the toolbox)
- Category: Post-Launch — agent tier, Phase 1
- Effort: M
- Dependencies: Agent Framework (#16), SmartMenu customer view (existing), `Allergyn` model (existing), `Menuparticipant` model (existing), OpenAI API with streaming

## Problem Statement
Guests arrive at the SmartMenu with varying dietary needs, group sizes, budgets, and taste preferences — but the current ordering experience is static browse-and-select. Customers with complex dietary requirements must manually scan every item for allergen information. Groups ordering together must coordinate verbally. Customers unfamiliar with a cuisine or wine list have no discovery aid beyond item descriptions. This friction reduces average order value, increases staff interruptions for dietary queries, and leaves high-margin items undiscovered. The Customer Concierge Agent addresses this by adding a natural-language discovery layer alongside the existing menu browse UI — allowing guests to describe what they want in plain language and receive an instant, personalised shortlist from the live menu. This is a customer-facing differentiator and a direct uplift to average order value.

## Success Criteria
- A customer can type a natural language query and receive a relevant shortlist of menu items within 2 seconds (visible streaming response begins within 800ms).
- Concierge engagement rate reaches 15% of SmartMenu sessions within 3 months of launch.
- Average order value for sessions that use the concierge is measurably higher than sessions that do not (track and report from week 1).
- The concierge correctly filters allergen-relevant items — a customer who states "I'm coeliac" never sees an item containing gluten in their recommendations.
- The standard menu browse experience is unchanged for customers who do not interact with the concierge — it is strictly additive.

## User Stories
- As a customer with dietary restrictions, I want to describe my needs in plain language and see only items I can safely eat, so I don't have to read every item description looking for allergens.
- As a customer ordering for a group, I want to describe the group's preferences and budget and receive a suggested basket, so we can order together without a lengthy discussion.
- As a customer unfamiliar with the menu, I want to ask "what's good here?" and receive a personalised recommendation, so I discover dishes I might otherwise have missed.
- As a restaurant owner, I want the concierge to recommend high-margin or featured items where appropriate, so it actively contributes to revenue rather than just acting as a search tool.
- As a developer, I want the concierge to work without requiring the customer to be signed in, so there is no friction barrier to using it.

## Functional Requirements

1. The concierge is accessed via an entry point in the SmartMenu customer view — a floating action button (FAB) or inline prompt bar labelled "Ask for help" or "Find something for me". The entry point must not obscure the standard menu browse layout.
2. The customer types a natural language query. The input is sent to a dedicated concierge endpoint via Turbo Stream or a lightweight AJAX call (not a full page navigation).
3. The concierge endpoint calls `Agents::CustomerConciergeService` (not a background job — this is synchronous request-response). The service:
   a. Reads the restaurant's current live menu using `read_restaurant_context` tool.
   b. Reads any dietary preferences stored in the `Menuparticipant` session (allergen filters already set by the customer).
   c. Calls OpenAI Responses API with the customer query, menu context, and dietary constraints. Uses streaming to begin returning results before the full LLM response is complete.
   d. Returns a ranked shortlist of up to 6 menu items with a one-sentence explanation per item.
4. Recommendations render as interactive menu item cards identical in style to the standard browse cards — same layout, same add-to-cart behaviour. Customers add items to their cart directly from the recommendation cards.
5. Group order mode: if the customer query includes group context ("for 4 people", "under €80 total"), the concierge calls the `propose_basket` tool to build a suggested complete order. The basket is displayed as a preview with a total. The customer can add all items with one tap or cherry-pick individual items.
6. Follow-up refinement: the customer can refine in context ("make it more vegetarian", "something lighter") without losing the previous recommendation. The input field remains open after the first response. Session context is held in the browser for the duration of the SmartMenu session (not persisted server-side).
7. The concierge always respects allergen filters. If the customer has `Menuparticipant` allergen filters set, or if the customer's query implies a dietary requirement, items that match the excluded allergens are never included in recommendations. This is enforced at the tool level, not by the LLM — the `search_menu_items` tool filters by allergen before passing items to the LLM.
8. The concierge responds in the customer's current locale. If the `Menuparticipant` locale is set to French, the concierge responds in French. The LLM is instructed to respond in the specified locale.
9. Common query patterns (e.g. "vegetarian options", "most popular items", "wine pairing for steak") are cached at the restaurant level using Rails cache (Memcached) with a 15-minute TTL to reduce LLM API calls during peak service.
10. The concierge does not add items to the cart autonomously — all cart modifications are explicit customer actions.
11. The concierge input is collapsed by default and must be explicitly activated by the customer — it does not interrupt the standard browsing experience.
12. Concierge interactions are logged as `AgentWorkflowRun` records with type `customer_concierge` for audit and analytics — but they are lightweight runs (no approval gate, no background jobs).

## Non-Functional Requirements
- Time to first visible response token: under 800ms (use OpenAI streaming).
- Full response time: under 2 seconds for a typical 6-item shortlist.
- The concierge endpoint must not block the Puma web thread for longer than 3 seconds — implement a server-sent event (SSE) or Turbo Stream streaming pattern.
- The concierge must work without the customer being signed in — it uses the `DiningSession` / `Menuparticipant` session context only.
- LLM calls from the concierge must be rate-limited per SmartMenu session (max 10 queries per session per hour) to prevent abuse and control API costs. Use Rack::Attack or a Redis counter.
- The concierge feature must be behind the `agent_customer_concierge` Flipper flag — disabled by default, enabled per restaurant.
- If the OpenAI API is unavailable, the concierge gracefully degrades: it displays a message ("Recommendations unavailable right now — browse the menu below") and the standard menu browse continues unaffected.
- Allergen enforcement at the tool level is non-negotiable — it must not be delegable to LLM judgement.
- No customer dietary data is persisted beyond the current `Menuparticipant` session without explicit opt-in.

## Technical Notes

### New Service (`app/services/agents/`)
- `agents/customer_concierge_service.rb` — synchronous (not a background job). Receives: `restaurant_id`, `smartmenu_session_token`, `query_text`, `conversation_history` (array of prior turns, max 5). Returns: streaming response via block/callback pattern, or a structured response hash for non-streaming fallback.

### New Tools to Add to Toolbox
- `tools/read_customer_preferences.rb` — reads `Menuparticipant` dietary flags and preferred locale for the current session
- `tools/compose_recommendation.rb` — generates natural language shortlist narrative with per-item explanations. Input: ranked item array + query context. Uses OpenAI.
- `tools/propose_basket.rb` — builds a complete suggested basket given group size and budget constraints. Input: item array, group_size, budget. Output: selected items with quantities and total.

### Extend Existing Tool
- `tools/search_menu_items.rb` — must support allergen exclusion filter as a mandatory parameter when allergens are present in session context. The allergen filter is applied in Ruby/SQL before the LLM sees the item list.

### New Controller
- `app/controllers/smartmenus/concierge_controller.rb`
- Route: `POST /t/:public_token/concierge/query`
- Responds with Turbo Stream or SSE for streaming. Falls back to JSON for non-streaming clients.
- Rate limiting: Redis counter per `dining_session_id`, 10 requests/hour. Return 429 with a friendly message if exceeded.

### New Stimulus Controller
- `app/javascript/controllers/concierge_controller.js` — manages the FAB/prompt bar UI: expand/collapse, submit query, render streaming response into recommendation cards, handle follow-up input.

### SmartMenu View Integration
- Add concierge FAB/prompt bar partial to `app/views/smartmenus/show.html.erb` (or equivalent customer view)
- Recommendation cards rendered using existing `menuitem` card partial — no new card component needed
- Concierge is conditionally rendered based on `Flipper.enabled?(:agent_customer_concierge, current_restaurant)`

### Caching
- Cache key: `concierge:#{restaurant_id}:#{query_hash}:#{menu_version_id}` (invalidate on menu change)
- TTL: 15 minutes
- Use existing Memcached/Dalli infrastructure

### Logging
- Create a lightweight `AgentWorkflowRun` record per concierge session (type: `customer_concierge`) for analytics — but do not create step-level records for each turn (too granular; just log turn count and outcome in the run's `context_snapshot`).
- Track: `query_text`, `item_count_returned`, `add_to_cart_count`, `session_id`. Do not store PII beyond what is already in `Menuparticipant`.

### Flipper Flags
- `agent_framework` — master switch (required)
- `agent_customer_concierge` — per-restaurant flag

## Acceptance Criteria
1. A customer on a SmartMenu with `agent_customer_concierge` enabled sees a concierge entry point (FAB or prompt bar) that does not obscure the menu browse layout.
2. Typing "I'm vegan, what can I eat?" and submitting returns a list of items with no animal products, with one-sentence explanations, rendered as standard menu item cards.
3. A customer who has allergen filter `gluten` set in their `Menuparticipant` record never receives an item containing gluten in a concierge recommendation — this is verified at the `search_menu_items` tool level, independent of the LLM response.
4. Typing "Build a tapas order for 4 people under €60" returns a basket preview with a total at or below €60 that the customer can add to cart in one action.
5. The first visible token of the LLM response is streamed to the browser within 800ms of the request being received by the server.
6. Submitting 11 queries in a single session within one hour returns a 429 response on the 11th request with a user-friendly message.
7. With `agent_customer_concierge` Flipper flag disabled for a restaurant, the concierge entry point is not rendered in the SmartMenu view.
8. If the OpenAI API returns a 503, the concierge displays "Recommendations unavailable right now" and the standard menu browse is unaffected.
9. A follow-up query ("make it more vegetarian") in the same session receives a response that is contextually aware of the previous exchange.
10. An `AgentWorkflowRun` record with type `customer_concierge` is created for the session and contains the query text and item count in its `context_snapshot`. No PII beyond the allergen/locale preferences already in `Menuparticipant` is stored.

## Out of Scope
- Persistent customer dietary profiles across visits without explicit sign-in and opt-in.
- Voice input for the concierge query (see Conversational & Voice Ordering R&D spec).
- Automated cart population without customer confirmation.
- Upsell scripting or hard-coded promotional injection — the concierge recommends based on menu data, not configured promotions.
- Social sharing of recommendations.
- Multi-restaurant concierge (the concierge is scoped to the current restaurant's menu only).

## Open Questions
1. Should the concierge entry point be a FAB (floating button, always visible) or an inline prompt bar at the top of the menu? The FAB risks covering menu content on mobile; the inline bar risks adding visual noise. Needs UX decision and mobile testing.
2. How many turns of conversation history should be retained in the browser session? Recommendation: 5 turns maximum to keep the LLM context window manageable and reduce cost — but this is a tunable parameter.
3. Should we track whether concierge recommendations convert to cart additions, and if so, how? The add-to-cart event from recommendation cards needs a `source: concierge` attribute to distinguish from standard browse additions in analytics.
4. Is there a GDPR consideration around logging `query_text` in `AgentWorkflowRun.context_snapshot`? Customers may type personal dietary information. Recommendation: log only structured output (item IDs returned, add-to-cart count) not the raw query text. Needs legal review.
