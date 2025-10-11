class Tag < ApplicationRecord
  include IdentityCache

  # Associations
  has_many :menuitem_tag_mappings, dependent: :destroy
  has_many :menuitems, through: :menuitem_tag_mappings

  # IdentityCache configuration
  cache_index :id
  cache_index :name
  cache_index :typs
  cache_index :archived

  # Cache associations
  cache_has_many :menuitem_tag_mappings, embed: :ids

  # Validations
  validates :name, presence: true
end
