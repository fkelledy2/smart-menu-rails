---
name: sommelier_controller.js injects unescaped server data into innerHTML — XSS via menu/pairing fields
description: buildCard, buildWineCard, renderPairingsModal all insert rec.name, rec.description, p.food_name, p.rationale etc. directly into innerHTML template literals without HTML escaping — stored XSS via staff-editable menu fields
type: project
---

In app/javascript/controllers/sommelier_controller.js:
- buildCard (line 265): rec.name, rec.description, rec.region, rec.story, tasting note fields, rec.best_pairing.food_name all injected raw
- buildWineCard (line 321): same fields
- renderPairingsModal (line 394): p.food_name, p.food_description, p.rationale all injected raw

The controller has no escapeHtml helper (unlike whiskey_ambassador_controller which had the same bug fixed previously).

Attack vector: any staff member who can edit menu item names/descriptions, food pairings, or tasting notes can inject arbitrary JavaScript that executes in every guest session that opens the Sommelier panel.

Fix: add an escapeHtml helper (identical to the one in inline_edit_controller.js) and wrap all server-sourced string interpolations with it.

**Why:** innerHTML does not escape HTML entities; template literals make this easy to miss.
**How to apply:** Never inject untrusted strings into innerHTML — use escapeHtml() or textContent.
