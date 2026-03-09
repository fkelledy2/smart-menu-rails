class AddPreferredLocalToOrderparticipant < ActiveRecord::Migration[7.1]
  def change
    add_column :ordrparticipants, :preferredlocale, :string
  end
end
