class SetDefaultPasswordChangedAt < ActiveRecord::Migration[7.2]
  def up
    User.where(password_changed_at: nil).update_all(password_changed_at: Time.current)
  end

  def down
    # No rollback needed
  end
end
