---
name: SassC rgba regression via StyleLint auto-fix
description: StyleLint duplicate-selector cleanup silently converts rgba() back to rgb() (4-arg) — SassC rejects 4-arg rgb(); file won't compile
type: feedback
---

StyleLint's auto-fixer, when merging duplicate selectors (e.g., `backdrop-filter: blur()` appearing twice), rewrites the block. If the merged block previously had `rgba()` tokens and the replacement comes from an older in-scope version that used `rgb()`, the rgba→rgb regression is introduced silently.

**Why:** The `e8b5afbf` commit (StyleLint fix) reverted the `b053295d` SassC fix for `_home.scss` by converting `rgba(r, g, b, a)` back to `rgb(r, g, b, a)` while merging the duplicate `backdrop-filter` lines. SassC (libsass) does not support 4-arg `rgb()` — it only accepts 3-arg. Files with 4-arg `rgb()` throw `wrong number of arguments (4 for 3) for 'rgb'` and fail to compile.

**How to apply:** After any StyleLint auto-fix pass, grep all modified SCSS files for `rgb([0-9]` patterns before committing. The check is: any `rgb(` with 4 comma-separated args. Also check for `width <=` / `width >=` range media query syntax — SassC rejects those too. Both must use `rgba()` and `max-width/min-width` respectively.

Files that have previously had this regression: `_home.scss`, `_dark_mode.scss`, `_component-overrides.scss`.

FIXED: Commit after `8ac051a4` — all three files converted back to `rgba()` and range query fixed to `max-width`.
