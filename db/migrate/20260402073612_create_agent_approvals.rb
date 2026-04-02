class CreateAgentApprovals < ActiveRecord::Migration[7.2]
  def change
    create_table :agent_approvals do |t|
      t.references :agent_workflow_run, null: false, foreign_key: true, index: true
      t.references :agent_workflow_step, foreign_key: true, index: true
      t.string :action_type, null: false
      t.string :risk_level, null: false, default: 'medium'
      t.jsonb :proposed_payload, null: false, default: {}
      t.string :status, null: false, default: 'pending'
      t.references :reviewer, foreign_key: { to_table: :users }, index: true
      t.datetime :reviewed_at
      t.text :reviewer_notes
      t.datetime :expires_at, null: false

      t.timestamps
    end

    add_index :agent_approvals, :status
    add_index :agent_approvals, :expires_at
    add_index :agent_approvals, [:status, :expires_at],
      name: 'idx_agent_approvals_status_expires_at'

    add_check_constraint :agent_approvals,
      "status IN ('pending','approved','rejected','expired')",
      name: 'agent_approvals_status_check'
    add_check_constraint :agent_approvals,
      "risk_level IN ('low','medium','high')",
      name: 'agent_approvals_risk_level_check'
  end
end
