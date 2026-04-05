class AddTwoFactorAuthToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :otp_secret_key, :string
    add_column :users, :otp_enabled, :boolean
    add_column :users, :otp_enabled_at, :datetime
    add_column :users, :otp_backup_codes, :text
    add_column :users, :otp_failed_attempts, :integer
    add_column :users, :otp_locked_until, :datetime
  end
end
