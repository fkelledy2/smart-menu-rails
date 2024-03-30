class AddNameToOrdrparticipants < ActiveRecord::Migration[7.1]
  def change
    add_column :ordrparticipants, :name, :string
  end
end
