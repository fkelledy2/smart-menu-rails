# Ambient Sensing & Restaurant State Detection

**Status:** Research / Strategy
**Feasibility:** Partially Feasible / Constrained by Current Platforms
**Target:** 2026+

## Vision

Use device and environment signals to tune interface density, pacing, and service recommendations.

## Included Ideas

- Noise sensing
- Lighting sensing
- Temperature-aware menu adaptation
- Automatic guest detection via WiFi presence

## Feasible Now

- Time-based and business-state heuristics as proxies
- Opt-in microphone-based noise estimation in narrow flows
- Presence heuristics from returning sessions and venue infrastructure where available

## Constraints

- Microphone, camera, and sensor permissions are sensitive
- Background sensing on the web is highly restricted
- Ambient light and temperature data are inconsistent across devices

## Suggested R&D Path

- Prefer inferred operational context over raw sensor capture
- Only request explicit sensor access where user value is obvious
- Use this to adapt UI density and pace before attempting deeper automation

## Strategic Value

- Makes the interface fit the moment better
- Can improve usability in loud, rushed, or low-attention environments
- Creates a richer context layer for future personalization
