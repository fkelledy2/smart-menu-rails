---
name: Navbar Duplicate HTML IDs
description: shared/_navbar has two elements with id="navbar-dropdown" and two with id="nav-account-dropdown" — invalid HTML, breaks ARIA and JS targeting
type: project
---

In app/views/shared/_navbar.html.erb, the Restaurants dropdown and the User account dropdown both use:
- id="navbar-dropdown" on the toggle link
- id="nav-account-dropdown" on the dropdown-menu div

This is invalid HTML (IDs must be unique per document). It also means aria-labelledby and data-target attributes point to the wrong element. Bootstrap's dropdown JS uses the toggle's data-bs-toggle="dropdown" so it works by DOM proximity, but ARIA screen reader associations are broken.

The Restaurants dropdown also uses data-bs-toggle="dropdown" inconsistently — it uses data: { bs_toggle: "dropdown" } (Rails data helper, produces data-bs-toggle) which is correct, but also data: { target: "nav-account-dropdown" } which is a non-Bootstrap attribute doing nothing.

Fix: Give each dropdown unique IDs (e.g., id="restaurants-nav-dropdown" / id="account-nav-dropdown") and update aria-labelledby accordingly.
