---
name: CrmExportService/WorkforceExportService @window_start uses unclamped window_minutes
description: Both export services clamp @window_minutes but compute @window_start from the raw unclamped argument — window mismatch when out-of-range values supplied
type: feedback
---

Both `PartnerIntegrations::CrmExportService` and `PartnerIntegrations::WorkforceExportService` initialize:
```ruby
@window_minutes = window_minutes.to_i.clamp(1, 1440)
@window_start   = window_minutes.minutes.ago   # ← uses unclamped value
```

If the caller passes `window_minutes: 0` or a negative number, `@window_minutes` is clamped to 1 but `@window_start` is `0.minutes.ago` (right now) or a future time — producing empty result sets with `window_minutes: 1` in the response. If the caller passes `window_minutes: 99999`, `@window_minutes` clamps to 1440 but queries span 99999 minutes — order_velocity in WorkforceExportService then divides by 1440 (clamped) while querying 69+ days of data.

**Why:** The clamp was applied to the instance variable but the `@window_start` assignment wasn't updated to use `@window_minutes`.

**How to apply:** Change line 18/19 in both services to use `@window_minutes.minutes.ago` instead of `window_minutes.minutes.ago`.
