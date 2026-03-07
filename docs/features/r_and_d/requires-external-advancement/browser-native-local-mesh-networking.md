# Browser-Native Local Mesh Networking

**Status:** Research / Strategy
**Feasibility:** Requires External Tech Advancement
**Target:** Future / TBD

## Vision

Enable nearby guest devices to discover and coordinate with each other locally through browser-native short-range networking primitives.

## Included Ideas

- Bluetooth mesh in the browser
- WiFi Direct browser-native peer networking
- Reliable local peer discovery without server mediation

## Why This Is Not Broadly Buildable Yet

- Browsers do not provide strong nearby discovery capabilities
- WebRTC alone does not solve local discovery and still requires signaling
- Bluetooth mesh and WiFi Direct are not mainstream browser primitives
- Security and permission models remain unresolved for broad consumer use

## What Can Be Done Beforehand

- Use server-backed realtime as the primary coordination model
- Experiment with WebRTC after explicit session joins
- Keep architecture modular so peer networking can be added later if the platform matures

## Strategic Value

- Could dramatically reduce coordination latency
- Opens the door to true local-first collaborative dining
- Would materially differentiate mellow.menu if the ecosystem enables it
