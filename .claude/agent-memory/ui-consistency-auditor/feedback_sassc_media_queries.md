---
name: feedback_sassc_media_queries
description: SassC rejects CSS range media query syntax — all stylesheets must use max-width/min-width
type: feedback
---

SassC (the Sass compiler used by this project via the sassc gem) does not support the
CSS Level 4 range media query syntax (`@media (width <= 768px)` or `@media (width >= 768px)`).
These must be written as `@media (max-width: 768px)` and `@media (min-width: 768px)` respectively.

**Why:** The project was bitten by this — commit b053295d and 5e94116b were both fixes for
this exact class of error. Despite those fixes, range syntax still appears in 19 Sass files
across the codebase (found in the March 2026 audit).

**How to apply:** Any time a media query is written or reviewed, use only `max-width:`/`min-width:`
notation. Never use `width <=`, `width >=`, or any parenthesised range syntax. Check with grep
before considering any Sass partial "clean".
