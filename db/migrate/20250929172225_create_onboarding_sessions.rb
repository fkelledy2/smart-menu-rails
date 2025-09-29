class CreateOnboardingSessions < ActiveRecord::Migration[7.1]
  def change
    create_table :onboarding_sessions do |t|
      t.references :user, null: true, foreign_key: true
      t.integer :status, default: 0, null: false
      t.text :wizard_data
      t.references :restaurant, null: true, foreign_key: true
      t.references :menu, null: true, foreign_key: true

      t.timestamps
    end
    
    add_index :onboarding_sessions, :status
    add_index :onboarding_sessions, :created_at
  end
end
