---
name: DeeplApiService hardcoded free-tier API URI
description: DeeplApiService hardcoded api-free.deepl.com; pro keys (no :fx suffix) need api.deepl.com — all pro translations fail
type: feedback
---

`DeeplApiService` at `app/services/deepl_api_service.rb` had `base_uri 'https://api-free.deepl.com/v2'` hardcoded at class level. DeepL free keys end with `:fx`; pro keys do not. Pro-key restaurants would receive HTTP 403 from the free-tier endpoint.

`DeeplClient` (unused in practice) already handled this correctly with `deepl_api_key&.end_with?(':fx')` logic.

Fixed: added `base_uri_for_key(key)` class method and updated `translate` to call `HTTParty.post` with the full absolute URL, bypassing the class-level `base_uri`.

Also aligned credential lookup: `DeeplApiService.api_key` now tries `credentials.dig(:deepl, :api_key)`, then `credentials.deepl_api_key`, then `ENV['DEEPL_API_KEY']` — matching what the initializer already does.

**Why:** Two parallel DeepL clients with diverging credential and URI logic is a recurring source of silent failures.

**How to apply:** Any new external API client with free/pro tier routing must implement URI selection at call time, not at class load time.
