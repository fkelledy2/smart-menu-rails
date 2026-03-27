# frozen_string_literal: true

class CreateCrmLeads < ActiveRecord::Migration[7.2]
  def change
    create_table :crm_leads do |t|
      t.string  :restaurant_name,     null: false
      t.string  :contact_name
      t.string  :contact_email
      t.string  :contact_phone
      t.string  :stage,               null: false, default: 'new'
      t.references :assigned_to,      null: true,  foreign_key: { to_table: :users }
      t.references :restaurant,       null: true,  foreign_key: true
      t.string  :source
      t.integer :notes_count,         null: false, default: 0
      t.datetime :last_activity_at
      t.datetime :converted_at
      t.datetime :lost_at
      t.string  :lost_reason
      t.text    :lost_reason_notes
      t.string  :calendly_event_uuid

      t.timestamps
    end

    add_index :crm_leads, :stage
    add_index :crm_leads, :last_activity_at
    add_index :crm_leads, :calendly_event_uuid,
              unique: true,
              where: 'calendly_event_uuid IS NOT NULL',
              name: 'index_crm_leads_on_calendly_event_uuid_partial'
  end
end
