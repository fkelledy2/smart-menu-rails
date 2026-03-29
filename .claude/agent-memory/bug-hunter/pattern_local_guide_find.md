---
name: LocalGuideGeneratorJob unsafe LocalGuide.find
description: LocalGuideGeneratorJob used LocalGuide.find — RecordNotFound crash if guide deleted between enqueue and execution (FIXED)
type: project
---

LocalGuideGeneratorJob#perform called `LocalGuide.find(local_guide_id)` which raises `ActiveRecord::RecordNotFound` when the guide is missing. Changed to `find_by` with an early return.

**Why:** Same pattern as SpotifyPlaylistSyncJob and GenerateWhiskeyFlightsJob — any job with a record lookup should use find_by.

**How to apply:** Consistent with the project pattern: all job record lookups use find_by + guard clause.
