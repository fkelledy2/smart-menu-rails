---
name: SmartmenusVoiceCommands find + VoiceCommandTranscriptionJob silent exception swallow
description: Two bugs: controller used Smartmenu.find (500 on bad ID) + job swallowed all exceptions returning nil
type: feedback
---

**Bug 1 — Controller:** `SmartmenusVoiceCommandsController#show` and `#create` (lines 7, 21) used `Smartmenu.find_by(slug: ...) || Smartmenu.find(id)`. The `Smartmenu.find` fallback raises `RecordNotFound` (500) instead of returning 404. `VoiceCommand...find(params[:id])` similarly raised on bad ID.

**Fix:** Extracted `find_smartmenu` helper that uses `find_by` for both slug and numeric ID. Changed `VoiceCommand.where(...).find` to `.find_by` with nil guard and `head :not_found`.

**Bug 2 — Job:** `VoiceCommandTranscriptionJob#perform` rescue block returned `nil` at end — Sidekiq never saw an exception and never retried, even on transient failures (network errors, OpenAI 429s).

**Fix:** Added `raise` at end of rescue block so Sidekiq's retry logic applies. Also added error logging.

**Why (Bug 2):** Jobs that swallow exceptions look like success to Sidekiq. The `sidekiq_options retry: 2` is useless if the job never raises. Always re-raise unless the error is truly unrecoverable (e.g., record deleted).

**How to apply:** Audit all job rescue blocks for `nil` or `false` at the end — these are silent swallows.
