# HTML Content in Localization

## Problem
Rails automatically escapes HTML content in translations for security reasons. When locale files contain HTML markup (like Bootstrap icons, formatting, etc.), the HTML tags are rendered as plain text instead of being interpreted as HTML.

## Solution
Use the `t_html()` helper method or `raw t()` to safely render HTML content from translations.

### Examples

**Locale file (config/locales/en.yml):**
```yaml
en:
  plan:
    starter:
      attribute1: "<li><i class='bi bi-check-lg'></i> For small cafes</li>"
      attribute2: "<li><i class='bi bi-check-lg'></i> <strong>1</strong> Restaurant</li>"
```

**View file (wrong - HTML will be escaped):**
```erb
<%= t('plan.starter.attribute1') %>
<!-- Renders: &lt;li&gt;&lt;i class='bi bi-check-lg'&gt;&lt;/i&gt; For small cafes&lt;/li&gt; -->
```

**View file (correct - HTML will be rendered):**
```erb
<%= t_html('plan.starter.attribute1') %>
<!-- Renders: <li><i class='bi bi-check-lg'></i> For small cafes</li> -->

<!-- Alternative syntax: -->
<%= raw t('plan.starter.attribute1') %>
```

### With Interpolation
```erb
<%= t_html('plan.starter.attribute2', locations: 1) %>
```

## Security Considerations
- Only use `t_html()` or `raw t()` with trusted translation content
- Never use with user-generated content
- Ensure HTML in locale files is properly formed
- Validate HTML structure in locale files

## Helper Method
The `t_html()` helper is defined in `ApplicationHelper`:

```ruby
def t_html(key, **options)
  raw t(key, **options)
end
```

This provides a clear, semantic way to indicate when HTML rendering is intentional.
