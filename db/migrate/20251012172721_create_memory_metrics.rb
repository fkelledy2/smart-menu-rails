class CreateMemoryMetrics < ActiveRecord::Migration[7.2]
  def change
    create_table :memory_metrics do |t|
      t.bigint :heap_size, null: false
      t.bigint :heap_free
      t.bigint :objects_allocated
      t.integer :gc_count
      t.bigint :rss_memory
      t.datetime :timestamp, null: false

      t.timestamps
    end
    
    add_index :memory_metrics, [:timestamp]
    add_index :memory_metrics, [:rss_memory, :timestamp]
  end
end
