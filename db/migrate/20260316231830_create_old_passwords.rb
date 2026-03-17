class CreateOldPasswords < ActiveRecord::Migration[7.2]
  def change
    create_table :old_passwords do |t|
      t.references :user, null: false, foreign_key: true
      t.string :encrypted_password

      t.timestamps
    end
  end
end
