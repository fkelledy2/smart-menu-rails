class FeaturesPlan < ApplicationRecord
  include IdentityCache

  belongs_to :plan
  belongs_to :feature

  # IdentityCache configuration
  cache_index :id
  cache_index :plan_id
  cache_index :feature_id
  cache_index :plan_id, :feature_id, unique: true

  # Cache associations
  cache_belongs_to :plan
  cache_belongs_to :feature

  # Validations
  validates :plan_id, uniqueness: { scope: :feature_id }
end
