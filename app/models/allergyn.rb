class Allergyn < ApplicationRecord
  include IdentityCache

  # EU 14 Major Allergens with standardized codes
  # Used for allergen legend display
  STANDARD_ALLERGENS = {
    'G' => 'Gluten (Cereals containing gluten)',
    'CR' => 'Crustaceans',
    'E' => 'Eggs',
    'F' => 'Fish',
    'P' => 'Peanuts',
    'SO' => 'Soy',
    'M' => 'Milk / Dairy',
    'N' => 'Tree Nuts',
    'CL' => 'Celery',
    'MU' => 'Mustard',
    'SE' => 'Sesame',
    'SU' => 'Sulphites',
    'LU' => 'Lupin',
    'MO' => 'Molluscs',
  }.freeze

  # Standard ActiveRecord associations
  belongs_to :restaurant
  has_many :menuitem_allergyn_mappings, dependent: :destroy
  has_many :menuitems, through: :menuitem_allergyn_mappings
  has_many :ordrparticipant_allergyn_filters, dependent: :destroy
  has_many :ordrparticipants, through: :ordrparticipant_allergyn_filters

  # Enums
  enum :status, {
    inactive: 0,
    active: 1,
    archived: 2,
  }

  # Validations
  validates :name, presence: true
  validates :symbol, presence: true

  # IdentityCache configuration
  cache_index :id
  cache_index :restaurant_id

  # Cache associations
  cache_belongs_to :restaurant
  cache_has_many :menuitem_allergyn_mappings, embed: :ids
  cache_has_many :ordrparticipant_allergyn_filters, embed: :ids
end
