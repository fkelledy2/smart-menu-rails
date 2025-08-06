class Menuitemlocale < ApplicationRecord
  include IdentityCache
  
  belongs_to :menuitem
  
  # IdentityCache configuration
  cache_index :id
  cache_index :menuitem_id
  
  # Cache associations
  cache_belongs_to :menuitem
end
