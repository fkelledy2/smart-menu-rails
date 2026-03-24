class AddPublicTokenToSmartmenus < ActiveRecord::Migration[7.2]
  def up
    add_column :smartmenus, :public_token, :string, limit: 64

    # Backfill existing rows in Ruby — SecureRandom.hex(32) produces 64-char hex
    # which satisfies the 256-bit entropy requirement without needing pgcrypto.
    connection.execute('SELECT id FROM smartmenus').each do |row|
      token = SecureRandom.hex(32)
      connection.execute(
        "UPDATE smartmenus SET public_token = '#{token}' WHERE id = #{row['id']}"
      )
    end

    change_column_null :smartmenus, :public_token, false
    add_index :smartmenus, :public_token, unique: true, name: 'index_smartmenus_on_public_token'
  end

  def down
    remove_index :smartmenus, name: 'index_smartmenus_on_public_token'
    remove_column :smartmenus, :public_token
  end
end
