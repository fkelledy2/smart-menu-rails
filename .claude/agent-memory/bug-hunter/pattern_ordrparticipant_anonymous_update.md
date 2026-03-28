---
name: OrdrparticipantsController#update allows anonymous cross-participant mutation
description: The update action skips verify_authorized and only calls authorize when current_user is set; anonymous users can PATCH /ordrparticipants/:id to update any participant's name, locale, or allergen filters without proving session ownership
type: project
---

`OrdrparticipantsController` (`app/controllers/ordrparticipants_controller.rb`):
- `after_action :verify_authorized, except: %i[index update]` — Pundit enforcement is bypassed for update
- `authorize @ordrparticipant if current_user` — only authorizes authenticated users
- Anonymous users bypass both checks entirely

Permitted params include `:name`, `:preferredlocale`, and `allergyn_ids:`. Since ordrparticipant IDs are sequential integers, an attacker who knows or guesses an ID can change another diner's displayed name and allergen filters (a food safety concern).

**Why:** The action was designed to allow anonymous smart-menu updates without session proof — the session ownership check was omitted.

**How to apply:** Add a session ownership check for anonymous callers (similar to `validate_guest_ordritem_ownership` in `OrdritemsController`) that verifies `Ordrparticipant.exists?(id: params[:id], sessionid: [session.id.to_s, session[:sid]])` before allowing the update.
