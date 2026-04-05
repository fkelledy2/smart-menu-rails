---
name: Stimulus controllers on disk + in manifest but missing from index.js
description: ordritem_tracking_controller, square_payment_controller, otp_input_controller were in manifest.js and on disk but not imported/registered in index.js — completely non-functional in production
type: project
---

Three controllers were present on disk and linked in `app/assets/config/manifest.js` but never imported or registered in `app/javascript/controllers/index.js`:
- `ordritem_tracking_controller.js` — real-time order item status updates for customers
- `square_payment_controller.js` — Square Web Payments SDK inline card UI
- `otp_input_controller.js` — OTP code input handling

Additionally `otp_input_controller` had its `import` statement placed after `application.register()` calls at the bottom of the file (appended by an automated tool). ES module imports must be at the top.

**Fix applied:** Added imports at the top of index.js and `application.register()` calls at the bottom for all three controllers.

**Why:** The CLAUDE.md requirement states both manifest.js AND index.js must be updated together when adding a new controller. This gap is not caught by CI or RuboCop.

**How to apply:** Any time a controller file is added, run the cross-check script to verify both files are updated.
