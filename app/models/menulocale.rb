class Menulocale < ApplicationRecord
  include IdentityCache

  # Standard ActiveRecord associations
  belongs_to :menu

  # IdentityCache configuration
  cache_index :id
  cache_index :menu_id

  # Cache associations
  cache_belongs_to :menu
end
