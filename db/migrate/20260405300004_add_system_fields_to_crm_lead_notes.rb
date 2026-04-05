# frozen_string_literal: true

# Adds `created_by_system` boolean so that automated job-authored notes
# can be stored without requiring a User record as the author.
class AddSystemFieldsToCrmLeadNotes < ActiveRecord::Migration[7.2]
  def change
    add_column :crm_lead_notes, :created_by_system, :boolean, null: false, default: false

    # Make author optional for system notes — enforce via model validation
    change_column_null :crm_lead_notes, :author_id, true
  end
end
