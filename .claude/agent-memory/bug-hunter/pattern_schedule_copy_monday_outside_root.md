---
name: Schedule copy-monday-btn outside data-menu-availabilities-root
description: copy-monday-btn is in the quick-actions-panel div, outside [data-menu-availabilities-root]; the JS looks for it inside root — always null
type: project
---

In `_schedule_2025.html.erb`, the "Copy Monday to All" button has class `copy-monday-btn` and lives in the `.quick-actions-panel` div at the top of the partial (lines 9–18). This div is outside the `<div data-menu-availabilities-root>` which starts at line 21.

The inline script does:
```js
const root = menuAvailabilitiesRoot(); // document.querySelector('[data-menu-availabilities-root]')
const copyButton = root.querySelector('.copy-monday-btn');
```

Since the button is not a descendant of `[data-menu-availabilities-root]`, `copyButton` is always `null`. The button appears in the UI but clicking it does nothing — the feature is completely dead.

**Fix**: Either move the button inside `[data-menu-availabilities-root]`, or change the querySelector to `document.querySelector('.copy-monday-btn')`.

**File**: `app/views/menus/sections/_schedule_2025.html.erb` lines 13 and 457
