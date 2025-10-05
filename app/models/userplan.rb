class Userplan < ApplicationRecord
  include IdentityCache
  
  belongs_to :user
  belongs_to :plan
  
  # IdentityCache configuration
  cache_index :id
  cache_index :user_id
  cache_index :plan_id
  
  # Cache associations
  cache_belongs_to :user
  cache_belongs_to :plan
end
