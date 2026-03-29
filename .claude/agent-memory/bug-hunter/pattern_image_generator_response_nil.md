---
name: MenuItemImageGeneratorJob response['data'] nil crash
description: MenuItemImageGeneratorJob accessed response['data'][0]['url'] without nil guard — NoMethodError on unexpected 200 responses
type: feedback
---

`MenuItemImageGeneratorJob#expensive_api_call` at `app/jobs/menu_item_image_generator_job.rb:58` accessed `response['data'][0]['url']` inside the `if response.success?` block. An OpenAI API 200 response with a content-policy rejection or empty data array would pass `success?` but have no `data` key, causing `NoMethodError: undefined method '[]' for nil`.

Fixed: reads `response.parsed_response['data']` into a variable first, gates the block on `image_data&.any?`.

**Why:** External API 200 responses can contain error payloads. Always nil-guard array access from parsed HTTP responses.

**How to apply:** Always use `response.parsed_response` consistently (not mixed `response[]` shorthand), and nil-guard any nested array access before indexing with `[0]`.
