# frozen_string_literal: true

class CreateCrmLeadTags < ActiveRecord::Migration[7.2]
  def change
    create_table :crm_lead_tags do |t|
      t.references :crm_lead, null: false, foreign_key: true
      t.string     :tag,      null: false

      t.datetime   :created_at, null: false
    end

    add_index :crm_lead_tags, %i[crm_lead_id tag],
              unique: true,
              name: 'index_crm_lead_tags_on_crm_lead_id_and_tag'
  end
end
