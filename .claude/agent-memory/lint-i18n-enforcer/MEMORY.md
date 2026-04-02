# Lint & i18n Enforcer — Memory Index

## Project / Codebase Patterns
- [project_locale_structure.md](project_locale_structure.md) — Locale files live in `config/locales/{locale}/` subdirectories, one file per feature area
- [project_brakeman_false_positives.md](project_brakeman_false_positives.md) — Two persistent Brakeman warnings that are pre-existing and verified safe

## Feedback / Conventions
- [feedback_rubocop_erb_false_positives.md](feedback_rubocop_erb_false_positives.md) — RuboCop reports Lint/Syntax on `.html.erb` files — these are expected false positives; only run RuboCop on `.rb` files
- [feedback_stimulus_i18n_pattern.md](feedback_stimulus_i18n_pattern.md) — Stimulus controllers must not hard-code user-facing strings; drive them from `data-*-value` attributes populated server-side via i18n
- [feedback_mailer_i18n_pattern.md](feedback_mailer_i18n_pattern.md) — HTML mailers: use `content_tag(:strong, val)` + `.html_safe` for inline bold in translated sentences; keep HTML out of locale values
