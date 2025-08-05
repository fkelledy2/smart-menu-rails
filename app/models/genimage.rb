class Genimage < ApplicationRecord
  include IdentityCache
  
  # Standard ActiveRecord associations
  belongs_to :restaurant
  belongs_to :menu, optional: true
  belongs_to :menusection, optional: true
  belongs_to :menuitem, optional: true
  
  # IdentityCache configuration
  cache_index :id
  cache_index :restaurant_id
  cache_index :menu_id
  
  # Cache associations
  cache_belongs_to :restaurant
  cache_belongs_to :menu
  cache_belongs_to :menusection
  cache_belongs_to :menuitem
end
