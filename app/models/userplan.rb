class Userplan < ApplicationRecord
  include IdentityCache

  belongs_to :user
  belongs_to :plan
  belongs_to :pricing_model, optional: true
  belongs_to :pricing_override_by_user, class_name: 'User', optional: true

  # IdentityCache configuration
  cache_index :id
  cache_index :user_id
  cache_index :plan_id

  # Cache associations
  cache_belongs_to :user
  cache_belongs_to :plan

  def price_locked?
    pricing_model_id.present? && applied_price_cents.present?
  end

  def pricing_version
    pricing_model&.version
  end

  def overridden_pricing?
    pricing_override_keep_original_cohort
  end
end
