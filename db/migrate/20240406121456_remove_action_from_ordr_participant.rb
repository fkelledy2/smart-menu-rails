class RemoveActionFromOrdrParticipant < ActiveRecord::Migration[7.1]
  def change
    remove_column :ordrparticipants, :action
  end
end