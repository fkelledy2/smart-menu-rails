# Server-Light Restaurant Floor Coordination

**Status:** Research / Strategy
**Feasibility:** Requires External Tech Advancement
**Target:** Future / TBD

## Vision

Allow restaurant-floor coordination to happen largely through nearby devices and local networks, with minimal dependency on a central cloud server.

## Included Ideas

- Full passive device-to-device restaurant floor coordination
- Local-first table, guest, and staff synchronization
- Reduced server mediation for collaborative ordering and restaurant interactions

## Why This Is Not Broadly Buildable Yet

- Local discovery and trust models are immature for browser apps
- Offline conflict resolution across many devices is complex
- Real-world reliability is not yet strong enough for service-critical restaurant operations
- Tooling and standards for web-native local-first coordination are still evolving

## What Can Be Done Beforehand

- Keep server-side realtime as the source of truth today
- Incrementally improve offline-read and local caching
- Use hybrid architectures that can absorb more local coordination later

## Strategic Value

- Could significantly reduce infrastructure dependency in the long run
- Would enable stronger resilience in poor-network environments
- Represents one of the clearest long-term moonshots for restaurant-floor software
