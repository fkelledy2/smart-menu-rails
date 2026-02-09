class ImpersonationAudit < ApplicationRecord
  belongs_to :admin_user, class_name: 'User'
  belongs_to :impersonated_user, class_name: 'User'

  validates :started_at, presence: true
  validates :expires_at, presence: true
end
