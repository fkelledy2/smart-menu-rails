---
name: Turbo-incompatible delete link_to
description: link_to with method: :delete is UJS (Rails 6) syntax; broken in Rails 7 + Turbo — must use data-turbo-method
type: project
---

`link_to @record, method: :delete` uses the old Rails UJS syntax. In Rails 7 with Turbo Drive, this issues a GET request instead of DELETE. The link silently fails (or navigates to the show page).

**Fix:** Replace with `data: { turbo_method: :delete, turbo_confirm: '...' }`.

**Found in:** `app/views/testimonials/edit.html.erb` (the Delete button in the edit header).

**How to apply:** Search for `method: :delete` in `link_to` calls across views. Any occurrence not using the Turbo data attributes will silently issue GET requests.
