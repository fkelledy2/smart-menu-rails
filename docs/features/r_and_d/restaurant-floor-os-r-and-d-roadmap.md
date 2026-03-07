# Restaurant Floor OS — R&D Roadmap

**Status:** Research / Strategy
**Priority:** High
**Target:** 2026+
**Theme:** Turn mellow.menu from a digital menu product into the operating system of the restaurant floor.

---

## 1. Purpose

This document groups exploratory product ideas into distinct R&D epics, with each epic classified as one of:

- **Currently feasible** — can be built now on the current web/mobile/browser stack, even if operationally difficult.
- **Partially feasible / constrained by current platforms** — some version is buildable now, but the full vision is limited by browser APIs, OS permissions, hardware access, or adoption friction.
- **Requires external tech advancement** — depends on future browser APIs, wider device hardware adoption, restaurant hardware rollout, or ecosystem change.

The strategic hypothesis is:

> **Phones are nodes, tables are objects, kitchens are event streams, and mellow.menu can become the coordination layer for the physical restaurant floor.**

---

## 2. Classification Summary

### Currently Feasible

- Context-aware menus
- Social dining intelligence
- Passive order tracking
- NFC smart table surfaces
- Crowd-sourced dish photography
- Table digital twins
- Bluetooth waiter paging
- Menu recommendation graph
- Voice ordering
- Restaurant gaming layer
- Camera-based dish recognition
- Automatic guest detection (limited forms)
- Cross-restaurant intelligence network
- Ultra-low latency menu rendering
- Restaurant digital atmosphere
- Distributed ordering system

### Partially Feasible / Constrained by Current Platforms

- Proximity-aware menus via WiFi/BLE heuristics
- Phone-to-phone mesh networking via WebRTC
- Augmented reality menus
- Ambient restaurant intelligence
- Cross-table communication
- Kitchen-aware menu pricing
- Smart payment swarms
- Local restaurant AI edge node
- Personal AI dining assistants

### Requires External Tech Advancement

- Ultra Wideband table detection as a mainstream web flow
- Bluetooth mesh / WiFi Direct browser-native peer networking
- Viral menu propagation via nearby device discovery in the browser
- Full passive device-to-device restaurant floor coordination without server mediation

---

## 3. Roadmap Principles

### 3.1 Strategic Filters

Each epic should be evaluated against:

- **Differentiation** — does this create a meaningful moat vs commodity QR menu tools?
- **Operational leverage** — does this reduce staff friction, table confusion, or service latency?
- **Data flywheel** — does this improve recommendations, forecasting, or personalization?
- **Hardware dependency** — can software ship first, or does it require table/kitchen/device hardware rollout?
- **Regulatory / privacy risk** — does it require consent for location, microphone, camera, payments, or proximity?

### 3.2 Recommended Investment Order

1. Build software-first epics with no hardware dependency
2. Build hardware-assisted epics using NFC / simple BLE first
3. Validate collaborative dining and AI personalization
4. Only then pursue moonshots requiring new browser/device capabilities

---

## 4. Epic 1 — Proximity-Aware Table Context

**Classification:** Partially feasible / constrained by current platforms

### Vision

Allow the system to infer or confirm which table a guest is physically at, reducing dependence on QR codes and lowering table spoofing.

### Included ideas

- Table-level positioning via WiFi + BLE heuristics
- Auto-assign orders to table
- Proximity-based menu opening with preselected table
- Ultra Wideband table detection

### Feasible now

- Phone joins restaurant WiFi, then the web app uses:
  - known SSID presence
  - previously scanned table context
  - optional user confirmation
  - coarse BLE-assisted native-app flows
- NFC or QR can be used as the trust anchor, then proximity can help confirm continuity.
- Staff-facing tools can use rough proximity signals operationally, even if not precise enough for full automation.

### Constraints

- Browsers have very limited access to WiFi and Bluetooth signal data.
- BLE scanning in browser contexts is permission-heavy and inconsistent.
- Server-side triangulation from browser signal telemetry is not broadly reliable on the open web.
- UWB is not broadly exposed in browser APIs.

### External advancement needed for full vision

- Browser-standardized access to richer proximity / ranging APIs
- Wider UWB hardware support and secure browser exposure
- Commodity table-side beacon/tag deployment at scale

### Suggested R&D path

#### Phase A

- NFC / QR anchored table identity
- Session continuity checks
- “Are you at Table 12?” confirmation UX

#### Phase B

- BLE/native-app experiments for higher-confidence table matching
- Fraud/spoofing scoring layer

#### Phase C

- UWB pilots if device/browser ecosystem matures

---

## 5. Epic 2 — Collaborative Dining Mesh

**Classification:** Partially feasible / constrained by current platforms

### Vision

Treat nearby guest devices as a temporary dining cluster that can coordinate cart state, session presence, and split ordering with minimal server dependence.

### Included ideas

- Phone-to-phone mesh networking
- Group ordering mesh
- Shared cart across phones
- WebRTC data channels
- Redis pubsub fallback
- Viral menu propagation / nearby join prompts
- Smart payment swarms

### Feasible now

- Shared-table ordering via server-backed realtime sync
- WebRTC data channels for explicit peer sessions once users are already connected
- Hybrid model:
  - server is source of truth
  - peer channels accelerate local coordination
- Split-bill negotiation and shared cart sync can be built today with ActionCable + WebRTC fallback experiments.

### Constraints

- Browser-based peer discovery is weak.
- WebRTC still needs signaling infrastructure.
- Bluetooth / AirDrop-like automatic nearby discovery is not broadly available to browser apps.
- Full serverless mesh reliability is poor in real-world dining environments.

### External advancement needed for full vision

- Better browser support for local discovery
- More reliable short-range peer APIs
- Standardized nearby sharing/discovery primitives for web apps

### Suggested R&D path

#### Phase A

- Build shared cart + participant sync with server-first realtime
- Add optional peer acceleration for low-latency updates

#### Phase B

- Experiment with WebRTC peer data channels for table participants
- Keep Redis / ActionCable as authoritative fallback

#### Phase C

- Revisit true mesh once discovery APIs improve

---

## 6. Epic 3 — Context-Aware Adaptive Menus

**Classification:** Currently feasible

### Vision

Menus adapt in real time based on table state, dwell time, kitchen conditions, weather, and inventory.

### Included ideas

- Time-at-table driven merchandising
- Weather-aware recommendations
- Crowd-level / kitchen-load adaptation
- Real-time ingredient-aware menu availability
- Restaurant digital atmosphere
- Noisy bar vs fine dining UI modes

### Feasible now

- Time-based promotion logic
- Weather API driven ranking
- Kitchen load scoring from order throughput / preparation queues
- Inventory-aware hiding or deprioritization
- Daypart / ambience-based theme shifts
- Dynamic ranking and merchandising based on existing menu + order telemetry

### Dependencies

- Reliable kitchen event stream
- Inventory freshness
- Rules engine or ranking engine
- Strong experimentation framework / feature flags

### Risks

- Over-personalization can feel manipulative
- Hiding items dynamically may frustrate guests if unexplained
- Kitchen-aware reprioritization must preserve menu trust

### Suggested R&D path

- Start with ranking, not hiding
- Add explainability labels such as:
  - “Quickest from kitchen”
  - “Popular tonight”
  - “Great for cold weather”

---

## 7. Epic 4 — Social Dining Intelligence

**Classification:** Currently feasible

### Vision

Surface table-level and restaurant-level social signals to increase confidence, discovery, and delight.

### Included ideas

- Real-time “what others ordered” at table
- Trending tonight
- “Chef just made fresh” highlights
- Cross-table social proof

### Feasible now

- Trending items from recent order stream
- “X people at this table ordered this” when privacy-safe
- Kitchen-originated freshness or limited-availability events
- Social proof widgets in-menu

### Constraints

- Privacy and consent around table-level aggregation
- Need minimum thresholds to avoid revealing individual choices

### Suggested R&D path

- Start with anonymous aggregates
- Add freshness signals from staff or kitchen tools
- A/B test whether social proof improves conversion without reducing exploration

---

## 8. Epic 5 — AR Menu Visualization

**Classification:** Partially feasible / constrained by current platforms

### Vision

Guests can preview dish size, presentation, and bottles in augmented reality directly on the table.

### Included ideas

- Camera mode
- 3D steak / dish previews
- Wine bottle size visualization
- Table-scale AR placement

### Feasible now

- Lightweight 3D previews
- AR-capable mobile experiences using platform/browser support where available
- “View in your space” for selected flagship dishes or bottles

### Constraints

- WebXR support is inconsistent across devices/platforms
- High-quality 3D asset creation is expensive
- UX value depends heavily on content quality and device support

### Suggested R&D path

- Start with premium/high-margin items only
- Use AR as an upsell enhancer, not a core navigation layer

---

## 9. Epic 6 — Ambient Sensing & Restaurant State Detection

**Classification:** Partially feasible / constrained by current platforms

### Vision

Use device and environment signals to tune interface density, pacing, and service recommendations.

### Included ideas

- Noise sensing
- Lighting sensing
- Temperature-aware menu adaptation
- Automatic guest detection via WiFi presence

### Feasible now

- Time-based and business-state heuristics as proxies
- Opt-in microphone-based noise estimation in narrow flows
- Presence heuristics from authenticated returning sessions and WiFi association patterns handled server-side where infrastructure exists

### Constraints

- Microphone/camera/ambient sensor permissions are sensitive
- Background sensing on the web is highly restricted
- Ambient light / temperature data availability is inconsistent

### Suggested R&D path

- Prefer inferred operational context over raw sensor capture
- Only use explicit sensor permissions where the guest benefit is obvious

---

## 10. Epic 7 — Live Order Journey & Passive Tracking

**Classification:** Currently feasible

### Vision

Guests get real-time awareness of where their food is in the fulfillment journey without needing waiter check-ins.

### Included ideas

- Passive order tracking
- Dish leaving kitchen notifications
- “Your food is arriving” push moments

### Feasible now

- Kitchen emits status events
- ActionCable / push notifications update guest UI
- Per-course or per-item lifecycle messaging

### Dependencies

- Reliable kitchen-side status transitions
- Notification strategy for web push / in-app state

### Strategic value

- Reduces anxiety
- Reduces staff interruption
- Makes the restaurant feel more responsive and modern

---

## 11. Epic 8 — Cross-Table Social & Commerce Layer

**Classification:** Partially feasible / constrained by current platforms

### Vision

Turn the dining room into a network where tables can interact, gift, vote, and participate in live restaurant moments.

### Included ideas

- Send drinks to another table
- Live dining polls
- Cross-table prompts and participatory moments

### Feasible now

- Server-mediated gifting between tables
- Live polls and event participation
- Table-targeted payments with staff approval workflow

### Constraints

- Requires strong abuse prevention
- Table addressing must be trustworthy
- Social features must fit venue tone and brand

### Suggested R&D path

- Start with opt-in experiences for events, tasting menus, bars, and hospitality-led venues

---

## 12. Epic 9 — Personal AI Dining Assistant

**Classification:** Partially feasible / constrained by current platforms

### Vision

Every guest gets an increasingly personalized dining layer that understands preferences, restrictions, and pairing behavior.

### Included ideas

- Persistent dining profiles
- Ingredient / dietary preference filtering
- AI wine or dish pairing
- Personalized menu ranking

### Feasible now

- Stored preference profiles
- Rules + embeddings + LLM ranking over menu content
- Pairing suggestions based on structured menu attributes
- Session-level and account-level personalization

### Constraints

- High-quality personalization requires enough repeat-user data
- Explanations and trust are critical
- Sensitive preference data must be handled carefully

### External advancement needed for full vision

- Better portable consumer identity/data layers across venues
- Lower-cost, high-reliability real-time inference everywhere

### Suggested R&D path

- Start with explicit preferences first
- Then layer inferred preferences
- Keep recommendations transparent and reversible

---

## 13. Epic 10 — Smart Table Entry Points

**Classification:** Currently feasible

### Vision

Replace QR-heavy initiation flows with faster, lower-friction physical touchpoints.

### Included ideas

- NFC smart table surfaces
- Tap-to-open table context

### Feasible now

- NFC tags embedded in tables or holders
- Deep-linked menu opening with signed table context
- Fast handoff with less visual clutter than QR

### Strategic value

- High UX win with relatively low R&D risk
- Good stepping stone toward more advanced proximity systems

### Suggested R&D path

- Treat NFC as the immediate successor to QR, not as a moonshot

---

## 14. Epic 11 — Crowd-Sourced Menu Media Graph

**Classification:** Currently feasible

### Vision

Use diner-submitted media to build a living, trustworthy visual layer for dishes and drinks.

### Included ideas

- Crowd-sourced dish photography
- Real photos from diners tonight

### Feasible now

- Photo upload flows
- Moderation pipeline
- Ranking by recency, quality, and trust
- Menu card enrichment with “real diner photo” provenance

### Constraints

- Requires moderation and abuse prevention
- Restaurant approval model may matter for brand-sensitive venues

### Strategic value

- Powerful data network effect
- Better authenticity than stock imagery

---

## 15. Epic 12 — Kitchen-Aware Commercial Optimization

**Classification:** Partially feasible / constrained by current platforms

### Vision

Use kitchen state to influence demand in real time through ranking, promotion, and potentially dynamic pricing.

### Included ideas

- Dynamic dish prioritization
- Dynamic pricing under kitchen pressure
- Demand steering away from overloaded stations

### Feasible now

- Ranking changes
- Promotion of quick-prep dishes
- Limited availability or surge-friction labels

### Constraints

- Dynamic pricing is commercially and reputationally sensitive
- Restaurants may prefer softer controls before price changes

### Suggested R&D path

- Start with recommendation and availability logic
- Only test price adjustments in narrow, explicit experimental cohorts

---

## 16. Epic 13 — Distributed Restaurant Operating Surface

**Classification:** Currently feasible

### Vision

Unify guest and staff device experiences into a shared ordering and coordination substrate.

### Included ideas

- Distributed ordering system
- Phones replace some fixed POS/table terminals
- Staff and guests use variants of the same interface

### Feasible now

- Staff handheld UI on the existing web stack
- Shared order/event model across customer and staff contexts
- Table and kitchen coordination via realtime updates

### Strategic value

- Strong product unification
- Reinforces “restaurant floor OS” framing

---

## 17. Epic 14 — Table Digital Twin & State Machine Layer

**Classification:** Currently feasible

### Vision

Represent each table as a live domain object with operational state that can drive UI, staff workflows, and automations.

### Included ideas

- Table digital twins
- Table state machine
- UI adapts to state, spend, course count, elapsed time

### Feasible now

- Explicit `Tablesetting` state projections
- Aggregated order/session state per table
- Automation hooks for nudges, staffing, and billing UX

### Strategic value

- Foundational layer for many other epics
- High reuse across guest, staff, kitchen, and analytics systems

---

## 18. Epic 15 — Staff Assistance & Proximity Response

**Classification:** Currently feasible

### Vision

Allow guests to summon staff digitally and route requests intelligently.

### Included ideas

- Bluetooth waiter paging
- Nearest waiter notification
- “Need assistance” requests

### Feasible now

- Digital assistance requests
- Staff app notifications based on station / zone assignment
- Simple proximity approximations from staff role/location context

### Constraints

- True nearest-device vibration by Bluetooth proximity is harder in browser-only flows
- Native staff apps would improve reliability

### Suggested R&D path

- Ship as zoned/station-based waiter paging first
- Add finer-grained routing later

---

## 19. Epic 16 — Recommendation & Taste Graph

**Classification:** Currently feasible

### Vision

Build collaborative filtering and graph-based recommendation systems around real dining behavior.

### Included ideas

- Menu recommendation graph
- “People who ordered this also ordered…”
- Pairing graph expansion

### Feasible now

- Collaborative filtering from order co-occurrence
- Session-based recommendations
- Restaurant-specific and network-wide recommendation layers

### Strategic value

- Improves conversion and average spend
- Creates a data moat that compounds with network size

---

## 20. Epic 17 — Edge Intelligence & Resilient Local Compute

**Classification:** Partially feasible / constrained by current platforms

### Vision

A restaurant can keep key intelligence and coordination running locally, with lower latency and partial resilience to internet outages.

### Included ideas

- Local restaurant AI edge node
- Mini-server / Raspberry Pi control plane
- Offline-tolerant AI and coordination

### Feasible now

- Local cache node
- Local event relay / sync worker
- Small-footprint recommendation or inference services on-premise

### Constraints

- Hardware management overhead
- Reliability/support complexity at restaurant level
- Deployment and update strategy becomes much harder

### Suggested R&D path

- First solve offline-read and local cache
- Only then test edge inference in premium or pilot venues

---

## 21. Epic 18 — Conversational & Voice Ordering

**Classification:** Currently feasible

### Vision

Enable guests to interact with the menu conversationally rather than only through tap-based browsing.

### Included ideas

- Voice ordering
- Natural language ordering
- Spoken modifications and preferences

### Feasible now

- Speech-to-text pipelines
- Intent extraction with LLMs or structured parsing
- Confirmation-based ordering UX

### Constraints

- Accuracy for accents, noise, and menu ambiguity
- Privacy concerns in shared dining environments

### Suggested R&D path

- Start with assisted voice search, not blind order submission
- Require explicit confirmation before sending to kitchen

---

## 22. Epic 19 — Interactive Dining Entertainment Layer

**Classification:** Currently feasible

### Vision

Use guest devices as an engagement surface while waiting, increasing dwell quality and retention.

### Included ideas

- Trivia while waiting
- Wine knowledge games
- Loyalty-linked table entertainment

### Feasible now

- Lightweight multiplayer or solo games
- Reward loops tied to loyalty or promotions
- Context-aware timing during wait states

### Constraints

- Must not cheapen premium dining experiences
- Best suited to selected venue types

---

## 23. Epic 20 — Camera-Driven Recognition & Reorder Flows

**Classification:** Currently feasible

### Vision

The camera becomes an input layer for dish recognition, reorder shortcuts, and menu education.

### Included ideas

- Camera-based dish recognition
- Photograph dish → identify it → reorder

### Feasible now

- Fine-tuned image classification or multimodal LLM recognition
- Assisted confirmation flows
- Reorder shortcuts linked to recognized menuitems

### Constraints

- Requires high-quality training/reference data
- Ambiguity for visually similar dishes

---

## 24. Epic 21 — Presence, Identity & Return-Guest Warm Start

**Classification:** Currently feasible

### Vision

Detect likely return guests and preload context before they actively begin ordering.

### Included ideas

- Automatic guest detection
- Menu preload on arrival

### Feasible now

- Logged-in session recall
- Returning-device heuristics with consent
- Location/venue entry hints from app/web session behavior

### Constraints

- Privacy and consent boundaries
- Must avoid feeling creepy or over-assumptive

### Suggested R&D path

- Focus on performance preloading, not silent identity assumptions

---

## 25. Epic 22 — Multi-Restaurant Intelligence Network

**Classification:** Currently feasible

### Vision

Aggregate learnings across venues to generate benchmarking, forecasting, and recommendation advantages.

### Included ideas

- Cross-restaurant intelligence network
- Best sellers across Florence
- Benchmarking and menu learning across locations

### Feasible now

- Aggregated analytics across restaurants
- Segment-specific benchmarking
- Trend transfer into recommendation and merchandising systems

### Constraints

- Must preserve tenant privacy and competitive boundaries
- Aggregate/anonymize aggressively

---

## 26. Epic 23 — Ultra-Low Latency Menu Runtime

**Classification:** Currently feasible

### Vision

Menus feel instantaneous, with load times approaching native-app responsiveness.

### Included ideas

- Edge caching
- local storage
- webassembly where useful
- sub-50ms open targets

### Feasible now

- Aggressive caching
- prefetching
- offline-ready shell
- local persistence of menu data
- incremental hydration / minimal JS boot paths

### Constraints

- Operational tuning, not scientific impossibility
- Requires disciplined performance engineering

### Strategic value

- Broadly improves every other epic
- Especially important for repeat guests and spotty network conditions

---

## 27. Moonshot Bets

If choosing three highest-upside strategic bets:

### 27.1 Collaborative Dining Mesh

Why:

- Strong differentiation
- Shared cart and participant coordination can become a social protocol for the table
- Creates network effects at the table level

### 27.2 Proximity-Based Table Detection

Why:

- Eliminates QR friction over time
- Makes the experience feel magical and secure
- Could become foundational infrastructure for identity, service routing, and table continuity

### 27.3 Personal AI Dining Assistant

Why:

- Long-term personalization moat
- Improves conversion, satisfaction, and retention
- Can compound across visits and venues

---

## 28. Recommended 12–24 Month R&D Sequence

### Horizon 1 — Build Now

Focus on high-leverage, software-first epics:

- Table digital twins
- Context-aware menus
- Passive order tracking
- Recommendation graph
- Crowd-sourced dish photography
- NFC smart table surfaces
- Cross-restaurant intelligence
- Ultra-low latency runtime

### Horizon 2 — Controlled Experiments

Run targeted pilots where platform constraints are acceptable:

- Shared cart / collaborative dining via server-first realtime + WebRTC experiments
- Personal AI assistant with explicit profiles
- AR visualization for premium dishes
- Ambient sensing proxies
- Waiter assistance routing

### Horizon 3 — Moonshots

Only pursue once ecosystem conditions improve:

- BLE / proximity-first table assignment without QR/NFC anchor
- UWB table precision
- Browser-native nearby discovery / mesh coordination
- Fully server-light restaurant floor networking

---

## 29. Strategic Conclusion

The largest opportunity is not to build isolated menu features.

It is to define a new systems model for restaurants:

- **phones = nodes**
- **tables = stateful objects**
- **kitchen = event stream**
- **staff = responsive agents**
- **menu = adaptive interface over live restaurant state**

In that framing, mellow.menu evolves from a digital menu product into:

> **the operating system of the restaurant floor.**

The best immediate R&D path is to ship the software-native foundation first, especially:

- table state machines
- adaptive menu logic
- realtime order journey
- personalized ranking
- NFC entry points
- low-latency runtime

Those create near-term value while setting up the more radical bets for later.
