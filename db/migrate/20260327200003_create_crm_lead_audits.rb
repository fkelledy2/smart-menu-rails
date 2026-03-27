# frozen_string_literal: true

class CreateCrmLeadAudits < ActiveRecord::Migration[7.2]
  def change
    create_table :crm_lead_audits do |t|
      t.references :crm_lead,  null: false, foreign_key: true
      t.references :actor,     null: true,  foreign_key: { to_table: :users }
      t.string  :actor_type,   null: false, default: 'user'
      t.string  :event,        null: false
      t.string  :field_name
      t.text    :from_value
      t.text    :to_value
      t.jsonb   :metadata,     null: false, default: {}

      t.datetime :created_at, null: false
    end
  end
end
