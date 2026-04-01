class Employee < ApplicationRecord
  include IdentityCache

  pay_customer

  # Standard ActiveRecord associations
  belongs_to :user
  belongs_to :restaurant
  has_many :ordrs, dependent: :destroy
  has_many :ordrnotes, dependent: :destroy
  has_many :employee_role_audits, dependent: :destroy
  has_many :role_changes_made, class_name: 'EmployeeRoleAudit', foreign_key: :changed_by_id, dependent: :nullify

  # PII encryption. email uses deterministic mode so the DB index remains usable.
  encrypts :name
  encrypts :email, deterministic: true

  # IdentityCache configuration
  cache_index :id
  cache_index :user_id
  cache_index :restaurant_id

  # Cache associations
  cache_belongs_to :user
  cache_belongs_to :restaurant

  # Cache invalidation hooks - DISABLED in favor of background jobs for performance
  # after_update :invalidate_employee_caches
  # after_destroy :invalidate_employee_caches

  enum :status, {
    inactive: 0,
    active: 1,
    archived: 2,
  }
  enum :role, {
    staff: 0,
    manager: 1,
    admin: 2,
  }
  validates :name, presence: true
  validates :eid, presence: true
  validates :role, presence: true
  validates :status, presence: true

  private

  def invalidate_employee_caches
    AdvancedCacheService.invalidate_employee_caches(id)
    AdvancedCacheService.invalidate_restaurant_caches(restaurant_id)
    AdvancedCacheService.invalidate_user_caches(restaurant.user_id) if restaurant.user_id
  end
end
