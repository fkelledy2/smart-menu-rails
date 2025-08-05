class Employee < ApplicationRecord
  include IdentityCache
  
  pay_customer

  # Standard ActiveRecord associations
  belongs_to :user
  belongs_to :restaurant
  has_many :ordrs, dependent: :destroy
  
  # IdentityCache configuration
  cache_index :id
  cache_index :user_id
  cache_index :restaurant_id
  
  # Cache associations
  cache_belongs_to :user
  cache_belongs_to :restaurant

  enum status: {
    inactive: 0,
    active: 1,
    archived: 2
  }
  enum role: {
    staff: 0,
    manager: 1,
    admin: 2
  }
  validates :name, :presence => true
  validates :eid, :presence => true
  validates :user, :presence => true
  validates :role, :presence => true
  validates :status, :presence => true
  validates :restaurant, :presence => true
end
