class CreateImpersonationAudits < ActiveRecord::Migration[7.2]
  def change
    create_table :impersonation_audits do |t|
      t.references :admin_user, null: false, foreign_key: { to_table: :users }
      t.references :impersonated_user, null: false, foreign_key: { to_table: :users }

      t.datetime :started_at, null: false
      t.datetime :ended_at
      t.datetime :expires_at, null: false

      t.string :ip_address
      t.string :user_agent

      t.string :ended_reason
      t.text :reason

      t.timestamps
    end

    add_index :impersonation_audits, :expires_at
    add_index :impersonation_audits, [:admin_user_id, :started_at]
    add_index :impersonation_audits, [:impersonated_user_id, :started_at]
  end
end
