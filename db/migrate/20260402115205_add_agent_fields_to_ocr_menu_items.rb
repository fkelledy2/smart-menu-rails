# frozen_string_literal: true

class AddAgentFieldsToOcrMenuItems < ActiveRecord::Migration[7.2]
  def change
    add_column :ocr_menu_items, :confidence_score, :float
    add_column :ocr_menu_items, :agent_approval_status, :string, default: 'pending'
    add_column :ocr_menu_items, :proposed_tags, :jsonb, default: []

    add_index :ocr_menu_items, :agent_approval_status,
              name: 'index_ocr_menu_items_on_agent_approval_status'
  end
end
