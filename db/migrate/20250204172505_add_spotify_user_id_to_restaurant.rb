class AddSpotifyUserIdToRestaurant < ActiveRecord::Migration[7.1]
  def change
    add_column :restaurants, :spotifyuserid, :string
  end
end
