class AddAssociationMappingIndexes < ActiveRecord::Migration[7.1]
  def change
    # Association mapping indexes for many-to-many relationships
    # These indexes optimize queries for menuitem attributes and filtering
    
    # Composite indexes for menuitem associations (reverse lookups)
    add_index :menuitem_allergyn_mappings, [:allergyn_id, :menuitem_id], 
              name: "index_menuitem_allergyn_on_allergyn_menuitem"
    
    add_index :menuitem_size_mappings, [:size_id, :menuitem_id], 
              name: "index_menuitem_size_on_size_menuitem"
    
    add_index :menuitem_tag_mappings, [:tag_id, :menuitem_id], 
              name: "index_menuitem_tag_on_tag_menuitem"
    
    add_index :menuitem_ingredient_mappings, [:ingredient_id, :menuitem_id], 
              name: "index_menuitem_ingredient_on_ingredient_menuitem"
    
    # Restaurant-scoped resource indexes (for filtering by restaurant)
    add_index :allergyns, [:restaurant_id, :status], 
              where: "archived = false", 
              name: "index_allergyns_on_restaurant_status_active"
    
    add_index :sizes, [:restaurant_id, :status], 
              where: "archived = false", 
              name: "index_sizes_on_restaurant_status_active"
    
    add_index :taxes, [:restaurant_id, :status], 
              where: "archived = false", 
              name: "index_taxes_on_restaurant_status_active"
    
    add_index :tips, [:restaurant_id, :status], 
              where: "archived = false", 
              name: "index_tips_on_restaurant_status_active"
    
    # Order participant allergy filter indexes
    add_index :ordrparticipant_allergyn_filters, [:ordrparticipant_id, :allergyn_id], 
              name: "index_ordrparticipant_allergyn_on_participant_allergyn"
  end
end
