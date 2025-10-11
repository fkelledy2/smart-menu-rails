class MenuitemTagMapping < ApplicationRecord
  include IdentityCache

  belongs_to :menuitem
  belongs_to :tag

  # IdentityCache configuration
  cache_index :id
  cache_index :menuitem_id
  cache_index :tag_id
  cache_index :menuitem_id, :tag_id, unique: true

  # Cache associations
  cache_belongs_to :menuitem
  cache_belongs_to :tag

  # Validations
  validates :menuitem_id, uniqueness: { scope: :tag_id }
end
