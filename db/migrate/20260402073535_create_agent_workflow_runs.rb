class CreateAgentWorkflowRuns < ActiveRecord::Migration[7.2]
  def change
    create_table :agent_workflow_runs do |t|
      t.references :restaurant, null: false, foreign_key: true, index: true
      t.string :workflow_type, null: false
      t.string :trigger_event, null: false
      t.string :status, null: false, default: 'pending'
      t.jsonb :context_snapshot, null: false, default: {}
      t.text :error_message
      t.datetime :started_at
      t.datetime :completed_at

      t.timestamps
    end

    add_index :agent_workflow_runs, :status
    add_index :agent_workflow_runs, :workflow_type
    add_index :agent_workflow_runs, [:restaurant_id, :status]
    add_index :agent_workflow_runs, :context_snapshot, using: :gin

    add_check_constraint :agent_workflow_runs,
      "status IN ('pending','running','awaiting_approval','completed','failed','cancelled')",
      name: 'agent_workflow_runs_status_check'
  end
end
