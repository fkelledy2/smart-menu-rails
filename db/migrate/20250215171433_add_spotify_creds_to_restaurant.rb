class AddSpotifyCredsToRestaurant < ActiveRecord::Migration[7.1]
  def change
    add_column :restaurants, :spotifyaccesstoken, :string
    add_column :restaurants, :spotifyrefreshtoken, :string
  end
end
