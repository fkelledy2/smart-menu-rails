---
name: Brakeman pre-existing warnings
description: Two Brakeman warnings present before the employee role feature that are verified safe
type: project
---

As of the 2026-04-02 sweep (after employee role feature + mailer i18n fixes), Brakeman reports exactly 2 warnings — both pre-existing and not introduced by recent changes:

1. **High / SQL Injection** — `app/controllers/api/v1/base_controller.rb:54`
   - `Restaurant.exists?(params[:restaurant_id])` — integer param, low actual risk but Brakeman flags it.

2. **Weak / Cross-Site Scripting** — `app/views/shared/_schema_org_json_ld.html.erb:2`
   - `json_escape(Rails.cache.fetch(...))` — the cached value is machine-generated JSON-LD from `SchemaOrgSerializer`, not user input.

**How to apply:** When running Brakeman, a clean result is 2 warnings. Any count above 2 means a new issue was introduced.
