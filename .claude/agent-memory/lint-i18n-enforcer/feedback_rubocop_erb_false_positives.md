---
name: RuboCop false positives on ERB files
description: RuboCop reports Lint/Syntax on .html.erb files — not real violations
type: feedback
---

When running RuboCop with explicit `.html.erb` file paths (e.g. when iterating over changed files), it reports `Lint/Syntax: unexpected token tLT` for every ERB file. This is a false positive — RuboCop attempts to parse the file as plain Ruby and chokes on `<%`.

**Why:** RuboCop's AllCops config excludes ERB files by path pattern, but passing the path explicitly bypasses that exclusion check in some versions.

**How to apply:** Only ever pass `.rb` file paths to RuboCop. For ERB linting, use `erb_lint` (if configured) or rely on Rails' own template rendering for syntax errors. Do not include view file paths in `rubocop` CLI invocations.
