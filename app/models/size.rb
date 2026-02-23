class Size < ApplicationRecord
  include IdentityCache

  # Standard ActiveRecord associations
  belongs_to :restaurant
  has_many :menuitem_size_mappings, dependent: :destroy
  has_many :menuitems, through: :menuitem_size_mappings

  # Enums
  enum :size, {
    xs: 0,
    sm: 1,
    md: 2,
    lg: 3,
    xl: 4,
  }

  enum :status, {
    inactive: 0,
    active: 1,
    archived: 2,
  }

  # Category distinguishes general sizes (xs/sm/md/lg/xl) from wine-specific sizes
  scope :wine, -> { where(category: 'wine') }
  scope :general, -> { where(category: 'general') }

  # IdentityCache configuration
  cache_index :id
  cache_index :restaurant_id

  # Cache associations
  cache_belongs_to :restaurant
  cache_has_many :menuitem_size_mappings, embed: :ids

  validates :name, presence: true
  validates :size, presence: true
end
