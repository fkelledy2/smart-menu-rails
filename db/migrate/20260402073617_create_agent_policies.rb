class CreateAgentPolicies < ActiveRecord::Migration[7.2]
  def change
    create_table :agent_policies do |t|
      t.references :restaurant, foreign_key: true, index: true
      t.string :action_type, null: false
      t.boolean :auto_approve, null: false, default: false
      t.string :escalation_email
      t.boolean :active, null: false, default: true
      t.integer :approval_expiry_hours, null: false, default: 72

      t.timestamps
    end

    # Unique per restaurant+action_type (null restaurant = global default)
    add_index :agent_policies, [:restaurant_id, :action_type], unique: true,
      name: 'idx_agent_policies_restaurant_action'
    add_index :agent_policies, :action_type
  end
end
