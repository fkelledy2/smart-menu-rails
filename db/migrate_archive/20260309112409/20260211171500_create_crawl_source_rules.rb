class CreateCrawlSourceRules < ActiveRecord::Migration[7.1]
  def change
    create_table :crawl_source_rules do |t|
      t.string :domain, null: false
      t.integer :rule_type, null: false, default: 0
      t.text :reason
      t.references :created_by_user, null: true, foreign_key: { to_table: :users }
      t.timestamps
    end

    add_index :crawl_source_rules, :domain, unique: true
    add_index :crawl_source_rules, :rule_type
  end
end
