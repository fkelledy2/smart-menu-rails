class MenuitemSizeMapping < ApplicationRecord
  include IdentityCache

  belongs_to :menuitem
  belongs_to :size

  # IdentityCache configuration
  cache_index :id
  cache_index :menuitem_id
  cache_index :size_id

  # Cache associations
  cache_belongs_to :menuitem
  cache_belongs_to :size

  def sizeName
    size.name
  end
end
