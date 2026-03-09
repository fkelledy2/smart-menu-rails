class AddLocalizationIndexes < ActiveRecord::Migration[7.1]
  def change
    # Localization indexes for multi-language support
    # These indexes optimize locale-specific queries across the application
    
    # Restaurant locales (restaurant scoping and locale lookup)
    add_index :restaurantlocales, [:restaurant_id, :locale], 
              name: "index_restaurantlocales_on_restaurant_locale"
    
    add_index :restaurantlocales, [:restaurant_id, :status, :dfault], 
              name: "index_restaurantlocales_on_restaurant_status_default"
    
    # Menu locales (menu scoping and locale lookup)
    add_index :menulocales, [:menu_id, :locale], 
              name: "index_menulocales_on_menu_locale"
    
    # Menuitem locales (menuitem scoping and locale lookup)
    add_index :menuitemlocales, [:menuitem_id, :locale], 
              name: "index_menuitemlocales_on_menuitem_locale"
    
    # Order participant locale preferences (session-based locale lookup)
    add_index :ordrparticipants, [:sessionid, :preferredlocale], 
              name: "index_ordrparticipants_on_session_locale"
    
    # Menu participant locale preferences (session-based locale lookup)
    add_index :menuparticipants, [:sessionid, :preferredlocale], 
              name: "index_menuparticipants_on_session_locale"
  end
end
