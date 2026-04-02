# frozen_string_literal: true

class AddAgentFieldsToOcrMenuImports < ActiveRecord::Migration[7.2]
  def change
    add_column :ocr_menu_imports, :agent_workflow_run_id, :bigint
    add_column :ocr_menu_imports, :confidence_score, :float
    add_column :ocr_menu_imports, :agent_status, :string, default: 'pending'

    add_index :ocr_menu_imports, :agent_workflow_run_id,
              name: 'index_ocr_menu_imports_on_agent_workflow_run_id'
    add_index :ocr_menu_imports, :agent_status,
              name: 'index_ocr_menu_imports_on_agent_status'
  end
end
