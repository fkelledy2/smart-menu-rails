class CreatePerformanceMetrics < ActiveRecord::Migration[7.2]
  def change
    create_table :performance_metrics do |t|
      t.string :endpoint, null: false
      t.float :response_time, null: false # milliseconds
      t.integer :memory_usage # bytes
      t.integer :status_code, null: false
      t.references :user, foreign_key: true, null: true
      t.string :controller
      t.string :action
      t.datetime :timestamp, null: false
      t.json :additional_data

      t.timestamps
    end
    
    add_index :performance_metrics, [:endpoint, :timestamp]
    add_index :performance_metrics, [:timestamp]
    add_index :performance_metrics, [:response_time]
    add_index :performance_metrics, [:status_code, :timestamp]
  end
end
