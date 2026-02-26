class CreateStaffInvitations < ActiveRecord::Migration[7.1]
  def change
    create_table :staff_invitations do |t|
      t.references :restaurant, null: false, foreign_key: true
      t.references :invited_by, null: false, foreign_key: { to_table: :users }
      t.string :email, null: false
      t.integer :role, null: false, default: 0
      t.string :token, null: false
      t.integer :status, null: false, default: 0
      t.datetime :accepted_at
      t.datetime :expires_at, null: false
      t.timestamps
    end

    add_index :staff_invitations, :token, unique: true
    add_index :staff_invitations, [:restaurant_id, :email], name: 'idx_staff_invitations_restaurant_email'
    add_index :staff_invitations, :status
  end
end
