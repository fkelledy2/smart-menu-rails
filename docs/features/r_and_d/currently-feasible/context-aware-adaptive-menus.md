# Context-Aware Adaptive Menus

**Status:** Research / Strategy
**Feasibility:** Currently Feasible
**Target:** 2026+

## Vision

Menus adapt in real time based on table state, dwell time, kitchen conditions, weather, and inventory.

## Included Ideas

- Time-at-table driven merchandising
- Weather-aware recommendations
- Crowd-level / kitchen-load adaptation
- Real-time ingredient-aware menu availability
- Restaurant digital atmosphere
- Noisy bar vs fine dining UI modes

## Feasible Now

- Time-based promotion logic
- Weather-driven ranking
- Kitchen load scoring from order throughput and preparation queues
- Inventory-aware hiding or deprioritization
- Daypart and ambience-based theme shifts

## Dependencies

- Reliable kitchen event stream
- Inventory freshness
- Rules engine or ranking engine
- Experimentation framework / feature flags

## Risks

- Over-personalization may feel manipulative
- Hiding items dynamically can frustrate guests if unexplained
- Kitchen-aware reprioritization must preserve menu trust

## Suggested R&D Path

- Start with ranking, not hiding
- Add explainability labels such as “Quickest from kitchen” and “Popular tonight”
- Expand toward more adaptive UI states once the ranking layer proves useful

## Strategic Value

- Improves conversion and average spend
- Helps restaurants steer demand operationally
- Makes the menu feel alive and context-aware
