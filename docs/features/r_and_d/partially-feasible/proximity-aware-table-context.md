# Proximity-Aware Table Context

**Status:** Research / Strategy
**Feasibility:** Partially Feasible / Constrained by Current Platforms
**Target:** 2026+

## Vision

Allow the system to infer or confirm which table a guest is physically at, reducing dependence on QR codes and lowering table spoofing.

## Included Ideas

- Table-level positioning via WiFi + BLE heuristics
- Auto-assign orders to table
- Proximity-based menu opening with preselected table

## Feasible Now

- Use restaurant WiFi presence, prior table context, and explicit confirmation UX
- Use NFC or QR as the trust anchor, then use proximity hints for continuity
- Use rough proximity signals operationally for staff workflows

## Constraints

- Browsers have limited access to WiFi and Bluetooth signal data
- BLE scanning in browser contexts is permission-heavy and inconsistent
- Server-side triangulation from browser telemetry is not broadly reliable on the open web

## Future Expansion

- Add native-app BLE experiments for stronger confidence
- Add spoofing/fraud scoring
- Use this as the stepping stone toward UWB-grade precision

## Suggested R&D Path

### Phase A

- NFC / QR anchored table identity
- Session continuity checks
- “Are you at Table X?” confirmation

### Phase B

- BLE/native-app experiments
- Confidence scoring for table matching

### Strategic Value

- Reduces QR dependence
- Improves trust in table identity
- Creates a more seamless arrival and ordering flow
