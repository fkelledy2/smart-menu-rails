---
name: Localization retry job symbol key access after JSON round-trip
description: MenuLocalizationRetryJob#retry_item_translation used symbol keys (item[:locale]) but Sidekiq JSON serialises args as string keys — all retries silently did nothing
type: project
---

`MenuLocalizationRetryJob#retry_item_translation` accessed `item[:locale]`, `item[:text]`, etc. with Ruby symbol keys. Sidekiq serialises job arguments as JSON, converting all symbol keys to strings. So on every retry job execution, `locale_code` and `text` were nil, and the method returned early without translating anything.

Additionally, `LocalizeMenuService#localize_all_menus_to_locale` was passing symbol-keyed hashes to `MenuLocalizationRetryJob.perform_in` without calling `.stringify_keys`, while the other path `localize_menu_to_all_locales` correctly did `map(&:stringify_keys)` first.

**Fix applied:**
- `MenuLocalizationRetryJob#retry_item_translation` now reads both string AND symbol keys: `item['locale'] || item[:locale]`
- `localize_all_menus_to_locale` now stringifies keys before enqueueing: `safe_items = stats[:rate_limited_items].map(&:stringify_keys)`

**How to apply:** Any time you pass a hash as a Sidekiq job argument, stringify keys before enqueue. The job must read string keys (or both) since JSON round-trip drops symbols.
