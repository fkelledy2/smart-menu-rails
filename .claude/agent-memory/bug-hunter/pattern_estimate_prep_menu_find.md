---
name: EstimatePrepTimesJob unsafe Menu.find
description: EstimatePrepTimesJob used Menu.find instead of find_by — RecordNotFound crash on missing menu_id (FIXED)
type: project
---

EstimatePrepTimesJob#perform line 9 called `Menu.find(menu_id)` which raises `ActiveRecord::RecordNotFound` when the menu no longer exists (e.g. deleted between enqueue and execution). Should be `find_by` with an early return.

Fix: replace `Menu.find(menu_id)` with `Menu.find_by(id: menu_id)` and `return if menu_id && menu.nil?`.

**Why:** Sidekiq retries the job on exceptions; a missing record is a permanent failure, not a transient one — retrying just burns retry slots.

**How to apply:** All Sidekiq jobs that load a record by id should use find_by + early return, not find.
