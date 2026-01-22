class AddLineKeyToOrdritems < ActiveRecord::Migration[7.2]
  def up
    add_column :ordritems, :line_key, :string

    require 'securerandom'

    Ordritem.reset_column_information
    Ordritem.find_in_batches(batch_size: 1000) do |batch|
      batch.each do |it|
        next if it.line_key.present?
        it.update_column(:line_key, SecureRandom.uuid)
      end
    end

    change_column_null :ordritems, :line_key, false
    add_index :ordritems, %i[ordr_id line_key], unique: true
  end

  def down
    remove_index :ordritems, column: %i[ordr_id line_key]
    remove_column :ordritems, :line_key
  end
end
