---
name: GenerateWhiskeyFlightsJob unguarded Menu.find
description: Menu.find raises ActiveRecord::RecordNotFound; triggers infinite Sidekiq retries
type: project
---

`Menu::GenerateWhiskeyFlightsJob#perform` used `::Menu.find(menu_id)` instead of `find_by`. When a menu is deleted between the time the job was enqueued and when it executes, Sidekiq retries the job on each `ActiveRecord::RecordNotFound`, causing unnecessary retry storms.

**Why:** ApplicationJob subclasses get ActiveJob's standard retry; without a nil guard the job just raises indefinitely.

**How to apply:** All jobs should use `find_by` + early return for record lookups. Only use `find` when the job should be discarded via `discard_on ActiveRecord::RecordNotFound`.
