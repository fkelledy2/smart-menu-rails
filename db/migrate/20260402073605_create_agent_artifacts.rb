class CreateAgentArtifacts < ActiveRecord::Migration[7.2]
  def change
    create_table :agent_artifacts do |t|
      t.references :agent_workflow_run, null: false, foreign_key: true, index: true
      t.string :artifact_type, null: false
      t.jsonb :content, null: false, default: {}
      t.string :status, null: false, default: 'draft'
      t.references :approved_by, foreign_key: { to_table: :users }, index: true
      t.datetime :approved_at

      t.timestamps
    end

    add_index :agent_artifacts, :status
    add_index :agent_artifacts, :artifact_type
    add_index :agent_artifacts, :content, using: :gin

    add_check_constraint :agent_artifacts,
      "status IN ('draft','approved','rejected','applied')",
      name: 'agent_artifacts_status_check'
  end
end
