---
name: menuparticipant_destroy_no_authorize
description: MenuparticipantsController#destroy is missing an authorize call; verify_authorized after_action (except: [:index]) will raise Pundit::AuthorizationNotPerformedError on every destroy request
type: project
---

`app/controllers/menuparticipants_controller.rb` line 90: the `destroy` action calls `@menuparticipant.destroy!` without any `authorize @menuparticipant` call. The controller declares `after_action :verify_authorized, except: [:index]`, so Pundit will raise `Pundit::AuthorizationNotPerformedError` when the action completes, causing a 500.

All other CRUD actions (show, new, edit, create, update) correctly call `authorize @menuparticipant`.

**Why:** destroy was added or overlooked when authorization was applied to the other actions.
**How to apply:** Add `authorize @menuparticipant` as the first line of the `destroy` action.
