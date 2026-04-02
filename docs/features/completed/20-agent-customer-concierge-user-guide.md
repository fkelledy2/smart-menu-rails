# Customer Dietary & Ordering Concierge — User Guide

**Feature**: #20 Customer Concierge Agent
**Status**: COMPLETED 2026-04-01
**Flipper flags**: `agent_framework` (global master) + `agent_customer_concierge` (per-restaurant)

---

## What it does

The Customer Concierge adds a natural-language discovery panel to the customer-facing SmartMenu. Guests can type a plain-language query ("I'm vegan and gluten-free", "build a tapas order for 4 under €60") and instantly receive a personalised shortlist of up to 6 matching menu items with one-sentence explanations.

Key characteristics:
- Allergen filters are enforced in SQL — items containing excluded allergens are never shown, regardless of the LLM response
- No sign-in required — the concierge works purely on the `DiningSession` / `Menuparticipant` session
- Multi-turn conversation — customers can refine ("make it more vegetarian") within the same session
- Group basket mode — queries like "for 4 people under €60" return a basket preview
- Graceful degradation — if OpenAI is unavailable, a friendly message is displayed and the standard menu browse is unaffected

---

## Enabling the concierge for a restaurant

The concierge is disabled by default. Enable it in two steps:

### 1. Enable the master agent flag (once per environment)

```ruby
Flipper.enable(:agent_framework)
```

This is the global master switch for all agent features. If it is already enabled (check via the Flipper UI at `/admin/flipper`), skip this step.

### 2. Enable the concierge for a specific restaurant

```ruby
restaurant = Restaurant.find(<id>)
Flipper.enable(:agent_customer_concierge, restaurant)
```

Or via the Flipper UI: search for `agent_customer_concierge`, then add the restaurant actor.

### Disabling for a restaurant

```ruby
Flipper.disable(:agent_customer_concierge, restaurant)
```

---

## Customer experience

Once enabled, customers visiting the SmartMenu (at `/t/:public_token`) will see an **inline prompt bar** near the top of the page, labelled "Find something for me".

1. Tapping the bar opens a panel with a text input.
2. The customer types a query and presses Enter or the send button.
3. The concierge queries the restaurant's live menu (filtered by any allergen exclusions the customer has already set) and returns up to 6 recommended items with explanations.
4. For group queries ("for 4 people under €60"), a basket preview is also shown with a total.
5. The customer can ask follow-up questions — the panel stays open and context is retained for up to 5 turns.

The standard menu browse is completely unaffected — the concierge is strictly additive.

---

## Allergen safety

Allergen enforcement is non-negotiable and operates at the database level:

- If the customer has allergen filters set (via the `Menuparticipant` / `OrdrparticipantAllergynFilter` flow), the `SearchMenuItems` tool excludes all items containing those allergens using a SQL `WHERE NOT IN` subquery **before** the item list is passed to the LLM.
- The LLM never sees allergen-excluded items; it cannot accidentally recommend them.
- This is verified in `test/services/agents/tools/search_menu_items_test.rb` — `test_call_excludes_items_with_specified_allergen_IDs`.

---

## Rate limiting

The concierge endpoint (`POST /t/:public_token/concierge/query`) is rate-limited via Rack::Attack:

| Throttle | Limit | Window | Key |
|----------|-------|--------|-----|
| `concierge/session` | 10 requests | 1 hour | Session cookie hash |
| `concierge/ip` | 60 requests | 1 hour | IP address |

When the session limit is exceeded, the endpoint returns HTTP 429 with a friendly JSON error. The spec requirement is 10 queries per session per hour.

---

## Caching

Common queries are cached at the restaurant + query-hash + menu-version level with a 15-minute TTL using the existing Memcached/Dalli infrastructure. Cache key format:

```
concierge:<restaurant_id>:<MD5(query_text)>:<menu_version_id>:<sorted_allergen_ids>
```

The cache is automatically invalidated when the menu version changes (the `menu_version_id` component of the key changes).

---

## Analytics

Each concierge session creates a lightweight `AgentWorkflowRun` record with `workflow_type: 'customer_concierge'`. The `context_snapshot` JSONB column stores:

- `smartmenu_id` — the SmartMenu the customer was viewing
- `turn_count` — number of queries in the session
- `item_count_returned` — items in the last recommendation
- `basket_proposed` — whether a basket was generated

Query analytics via Rails console:

```ruby
# Sessions for a restaurant today
AgentWorkflowRun
  .where(restaurant: restaurant, workflow_type: 'customer_concierge')
  .where('created_at > ?', Time.current.beginning_of_day)
  .count

# Average items returned
AgentWorkflowRun
  .where(workflow_type: 'customer_concierge')
  .average("(context_snapshot->>'item_count_returned')::int")
```

No raw query text is stored by default. The `context_snapshot` stores structured output only.

---

## Files shipped

| File | Purpose |
|------|---------|
| `app/services/agents/customer_concierge_service.rb` | Main orchestration service (synchronous) |
| `app/services/agents/tools/read_customer_preferences.rb` | Reads allergen exclusions and locale from session |
| `app/services/agents/tools/compose_recommendation.rb` | Calls OpenAI to generate shortlist narrative |
| `app/services/agents/tools/propose_basket.rb` | Greedy basket builder for group queries |
| `app/services/agents/tools/search_menu_items.rb` | Extended with `exclude_allergyn_ids` parameter |
| `app/controllers/smartmenus/concierge_controller.rb` | Public POST endpoint for queries |
| `app/views/smartmenus/_concierge.html.erb` | Panel partial (prompt bar + results) |
| `app/javascript/controllers/concierge_controller.js` | Stimulus controller (open/close, fetch, render) |
| `app/assets/stylesheets/components/_concierge.scss` | Panel CSS |
| `config/routes.rb` | `POST /t/:public_token/concierge/query` |
| `config/initializers/rack_attack.rb` | Rate limit throttles |

---

## Troubleshooting

**Concierge bar not visible on SmartMenu**
- Confirm `agent_framework` is enabled globally.
- Confirm `agent_customer_concierge` is enabled for the specific restaurant actor.
- The bar is only rendered in customer view (not staff preview mode).

**"Recommendations unavailable right now" shown to customer**
- OpenAI API may be unavailable or returning errors. Check `AgentWorkflowRun.where(workflow_type: 'customer_concierge', status: 'failed').last.error_message`.
- Verify `OPENAI_API_KEY` is set in the environment.

**Customer receives allergen-flagged items**
- This should be impossible by design. If it occurs, check that the `MenuitemAllergynMapping` records are correctly set for the item, and that the customer's allergen filters are stored in `OrdrparticipantAllergynFilter`. File a bug immediately.

**Rate limit hit in testing**
- Rack::Attack is disabled in the test environment (`Rack::Attack.enabled = !Rails.env.test?`).
