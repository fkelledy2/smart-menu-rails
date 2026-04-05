---
name: invisible_captcha already installed
description: invisible_captcha ~> 2.3 is in the Gemfile and has an initializer but is not yet wired to any controller or view — just activate it
type: project
---

`invisible_captcha ~> 2.3` is present in `Gemfile` and configured in `config/initializers/invisible_captcha.rb` (honeypots: [:subtitle, :tagline], timestamp_threshold: 2, timestamp_enabled: true, injectable_styles: false). However as of 2026-04-04 it is not wired to any controller or view. To activate for a specific form: add `invisible_captcha scope: :model_name, on_spam: :handler` to the controller and `<%= invisible_captcha %>` inside the form_with block in the view.

**Why:** Needed for spec #39 (Lead Enrichment + Contact Form Spam Protection). Discovered during codebase research that the gem was installed but unused.

**How to apply:** When speccing spam protection for any public-facing form, note that activation cost is minimal — the gem infrastructure is already there. No new gem install required.
