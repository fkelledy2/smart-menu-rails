# Views Style Guide (Smart Menu)

This guide documents conventions for ERB/HTML views across the app, with a focus on consistency, maintainability, and accessibility. These rules are enforced (where possible) by erb-lint.

## Formatting
- Indentation: 2 spaces for all HTML and ERB blocks.
- Trailing whitespace: none. Final newline required.
- ERB tag spacing:
  - Use one space after `<%=` and before `%>`.
  - Prefer `<%= %>` for output, `<% %>` for logic.
- Attributes: wrap long attribute lists onto multiple lines.
- Boolean attributes: keep consistent usage across a file (e.g., `disabled` vs `disabled="disabled"`).

## Partials & Structure
- Extract duplicated blocks into partials. Name partials clearly and keep their scope small:
  - `smartmenus/_tasting_courses_footer.erb`
  - `smartmenus/_modal_header_add_item.erb`
  - `smartmenus/_modal_footer_add_item.erb`
  - `smartmenus/_modal_footer_primary.erb`
- Pass locals explicitly; avoid dependence on implicit scope.
- For partials rendered from different scopes, use explicit i18n keys (see i18n).

## CSS & Utilities
- Avoid inline styles. Prefer utility classes in SCSS (e.g., `_utilities.scss`).
  - Example utilities:
    - `br-bottom-right-4` for bottom-right radius used in tasting CTA.
    - `modal-footer-spaced` for modal footer padding/gap/justify.
- Keep component-specific styles within the appropriate component/page stylesheet.

## Data Attributes & Test Hooks
- JS hooks: use `data-*` attributes with stable names (e.g., `data-tasting-meta`, `data-section-id`).
- Test hooks: use `data-testid` consistently. Do not rename existing test IDs without updating tests.

## Accessibility (A11y)
- Icon-only buttons must have an accessible name: add `aria-label`.
- Decorative icons must be hidden from screen readers: `aria-hidden="true"`.
- Ensure labels are associated with inputs (via `for`/`id` or wrapping).
- Modals must have `aria-labelledby` pointing to a visible title.
- Inputs should include an `autocomplete` attribute when appropriate. If no autocomplete is desired, use `autocomplete="off"`.

## i18n
- Do not hardcode user-facing strings in partials when a translation exists.
- When rendering partials from multiple scopes, use explicit keys to avoid scope surprises:
  - `t('smartmenus.showModals.addToOrder')`
  - `t('smartmenus.showModals.cancel')`
- Maintain existing strings if tests depend on them. Migrate to i18n gradually.

## Modal Patterns
- Standardize modal headers and footers via shared partials.
- Keep IDs stable (e.g., `addItemToOrderButton`, `request-bill`, `pay-order`).
- Use the `modal-footer-spaced` utility for spacing instead of inline styles.

## Linting
- Use `erb_lint` with the provided `.erb_lint.yml` for safe formatting and consistency.
  - Report-only: `bundle exec erb_lint app/views`
  - Autocorrect (safe rules only): `bundle exec erb_lint app/views --autocorrect`

## Commit Practices
- Group mechanical formatting changes separately from functional changes.
- Use clear messages, e.g., `chore(views): formatting`, `chore(views): de-dup modal footer`, `chore(views): a11y aria-labels`.

