---
name: EmptyStateComponent API
description: ViewComponent for empty states — params, icon map, and both usage patterns (direct component render and shared/_empty_state partial wrapper)
type: project
---

File: app/components/empty_state_component.rb + .html.erb
Wrapper partial: app/views/shared/_empty_state.html.erb

Params:
- title: String (required)
- description: String (optional)
- icon: Symbol from ICON_MAP or raw "bi-*" string (default :default)
- action_text: String (optional CTA label)
- action_url: String (optional CTA URL)
- action_method: Symbol (default :get)
- compact: Boolean (default false) — renders .empty-state--compact

ICON_MAP keys: :menu, :cart, :search, :table, :staff, :order, :item, :section, :allergen, :default

Usage — ViewComponent directly:
  render(EmptyStateComponent.new(title: '...', icon: :menu))

Usage — partial wrapper:
  render 'shared/empty_state', title: '...', icon: :item, action_text: 'Add', action_url: new_path

Inconsistency: The JWT token index and Demo Bookings index use hand-rolled empty states (div.text-center.py-5.text-muted with bi icon) instead of EmptyStateComponent. These should be migrated to the component for consistency.

CSS: .empty-state styles are in components/_empty_states.scss. The .empty-state--compact variant only modifies padding/min-height via the parent but the compact class is not actually defined in the SCSS — it relies on the parent .empty-state having smaller padding overrides. Minor gap.
