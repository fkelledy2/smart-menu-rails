class CreateSlowQueries < ActiveRecord::Migration[7.2]
  def change
    create_table :slow_queries do |t|
      t.text :sql, null: false
      t.float :duration, null: false # milliseconds
      t.string :query_name
      t.text :backtrace
      t.datetime :timestamp, null: false

      t.timestamps
    end
    
    add_index :slow_queries, [:duration, :timestamp]
    add_index :slow_queries, [:timestamp]
  end
end
