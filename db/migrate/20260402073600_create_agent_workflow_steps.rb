class CreateAgentWorkflowSteps < ActiveRecord::Migration[7.2]
  def change
    create_table :agent_workflow_steps do |t|
      t.references :agent_workflow_run, null: false, foreign_key: true, index: true
      t.string :step_name, null: false
      t.integer :step_index, null: false
      t.string :status, null: false, default: 'pending'
      t.jsonb :input_snapshot, null: false, default: {}
      t.jsonb :output_snapshot, null: false, default: {}
      t.text :last_error
      t.integer :retry_count, null: false, default: 0
      t.datetime :started_at
      t.datetime :completed_at

      t.timestamps
    end

    add_index :agent_workflow_steps, [:agent_workflow_run_id, :step_index], unique: true,
      name: 'idx_agent_steps_run_id_step_index'
    add_index :agent_workflow_steps, :status

    add_check_constraint :agent_workflow_steps,
      "status IN ('pending','running','completed','failed','skipped')",
      name: 'agent_workflow_steps_status_check'
  end
end
