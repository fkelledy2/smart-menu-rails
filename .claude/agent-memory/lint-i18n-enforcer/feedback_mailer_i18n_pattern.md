---
name: Mailer i18n pattern with inline HTML interpolation
description: How to i18n mailer views that embed <strong> tags inside translated sentences
type: feedback
---

When a translated sentence needs to wrap interpolated values in `<strong>` tags (common in mailer HTML views), use `content_tag(:strong, value)` as the interpolation argument and call `.html_safe` on the `t()` result:

```erb
<%= t('employee_mailer.role_changed.intro',
      restaurant: content_tag(:strong, @restaurant.name),
      changed_by: content_tag(:strong, @changed_by.name)).html_safe %>
```

The locale string uses plain `%{restaurant}` and `%{changed_by}` placeholders — no HTML in the locale file itself. The `.html_safe` call is safe here because `content_tag` escapes the interpolated values.

For the plain-text mailer version of the same action, pass the raw string values (no `content_tag`) — no `.html_safe` needed.

**Why:** Keeps HTML out of locale strings (which go through DeepL) while allowing bold formatting in emails. Avoids double-encoding of restaurant names.

**How to apply:** Any time a mailer template needs bold/italics around an interpolated name, use `content_tag` + `.html_safe`. Do not embed `<strong>` directly in the locale value.
