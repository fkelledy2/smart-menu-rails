class AddScheduledApplyAtToAgentArtifacts < ActiveRecord::Migration[7.2]
  def change
    add_column :agent_artifacts, :scheduled_apply_at, :datetime
    add_index :agent_artifacts, :scheduled_apply_at,
      name: 'index_agent_artifacts_on_scheduled_apply_at'
  end
end
