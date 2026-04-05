---
name: CRM set_lead before_action missing and return — action body executes on nil lead
description: EmailSendsController, NotesController, AuditsController set_lead had head :not_found without and return (FIXED)
type: project
---

All three CRM admin controllers (`EmailSendsController`, `NotesController`, `AuditsController`) had:

```ruby
def set_lead
  @lead = CrmLead.find_by(id: params[:lead_id])
  head :not_found unless @lead  # BUG: missing and return
end
```

When `@lead` is nil, `head :not_found` is sent but the action body continues executing with `@lead = nil`, raising NoMethodError on the first `@lead.` call.

Fixed to `head :not_found and return unless @lead` in all three.

**Why:** Copied pattern from set_lead in leads_controller.rb which used the correct `head :not_found and return` form. The newer controllers dropped the `and return`.

**How to apply:** Whenever writing a `before_action` guard that calls `head` or `render`, always use `and return` or `return` prefix to halt the filter chain.
