class AddIdempotencyKeyToAgentApprovals < ActiveRecord::Migration[7.2]
  def change
    add_column :agent_approvals, :idempotency_key, :string

    add_index :agent_approvals, :idempotency_key,
      unique: true,
      where: 'idempotency_key IS NOT NULL',
      name: 'index_agent_approvals_on_idempotency_key'
  end
end
