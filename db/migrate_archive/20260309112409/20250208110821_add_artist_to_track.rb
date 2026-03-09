class AddArtistToTrack < ActiveRecord::Migration[7.1]
  def change
    add_column :tracks, :artist, :string
    add_column :tracks, :explicit, :boolean
    add_column :tracks, :is_playable, :boolean
    add_column :tracks, :status, :integer
  end
end
