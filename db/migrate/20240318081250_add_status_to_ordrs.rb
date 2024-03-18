class AddStatusToOrdrs < ActiveRecord::Migration[7.1]
  def change
    add_column :ordrs, :status, :integer
  end
end
