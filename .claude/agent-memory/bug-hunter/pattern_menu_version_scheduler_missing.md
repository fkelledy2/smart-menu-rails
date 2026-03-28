---
name: Menu version scheduled activation never fires — no scheduler job existed
description: MenuVersionActivationService.activate! with starts_at/ends_at stored is_active:false with timestamps but no job/cron ever applied the schedule
type: project
---

`MenuVersionActivationService.activate!` when called with `starts_at` or `ends_at` saves the version with `is_active: false` plus the timestamps. There was no job, cron, or sweep that ever checked those timestamps and flipped `is_active` to `true`. The feature was completely dead — calling "Schedule Version" from the UI appeared to succeed but the version never went live.

**Fix applied:**
- Created `app/jobs/menu_version_scheduler_job.rb` — queries for versions where `starts_at <= now` and `ends_at IS NULL OR ends_at > now` and activates them; also deactivates versions past `ends_at`
- Added `every 5.minutes { runner 'MenuVersionSchedulerJob.perform_later' }` to `config/schedule.rb`

**How to apply:** When a feature stores "intent" metadata (starts_at/ends_at) alongside a boolean state flag, always verify there is a scheduled job that actually applies the intent. Pattern of is_active: false + schedule timestamps = needs a sweeper job.
