# frozen_string_literal: true

class CreateCrmLeadNotes < ActiveRecord::Migration[7.2]
  def change
    create_table :crm_lead_notes do |t|
      t.references :crm_lead, null: false, foreign_key: true
      t.references :author,   null: false, foreign_key: { to_table: :users }
      t.text :body,           null: false

      t.timestamps
    end
  end
end
