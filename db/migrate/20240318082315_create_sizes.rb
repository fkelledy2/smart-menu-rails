class CreateSizes < ActiveRecord::Migration[7.1]
  def change
    create_table :sizes do |t|
      t.integer :size
      t.string :name
      t.text :description

      t.timestamps
    end
  end
end
