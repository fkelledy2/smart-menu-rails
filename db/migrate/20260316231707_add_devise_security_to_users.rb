class AddDeviseSecurityToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :password_changed_at, :datetime
    add_column :users, :encrypted_password_salt, :string
    add_column :users, :encrypted_password_iv, :string
    add_column :users, :session_limitable, :integer
    add_column :users, :unique_session_id, :string
    add_column :users, :last_activity_at, :datetime
    add_column :users, :expired_at, :datetime
  end
end
