class Feature < ApplicationRecord
  include IdentityCache

  # Associations
  has_many :features_plans, dependent: :destroy
  has_many :plans, through: :features_plans

  # IdentityCache configuration
  cache_index :id
  cache_index :key, unique: true
  cache_index :status

  # Cache associations
  cache_has_many :features_plans, embed: :ids

  # Validations
  validates :key, presence: true, uniqueness: true
  validates :descriptionKey, presence: true
end
