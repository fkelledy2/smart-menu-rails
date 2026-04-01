# EmployeeRoleAudit — immutable audit log for employee role changes.
# Records are append-only: no update or delete actions are permitted
# via the application (enforced at the Pundit policy level).
class EmployeeRoleAudit < ApplicationRecord
  belongs_to :employee
  belongs_to :restaurant
  belongs_to :changed_by, class_name: 'Employee'

  # Mirror the Employee role enum values so we can use human-readable names.
  enum :from_role, { staff: 0, manager: 1, admin: 2 }, prefix: :from
  enum :to_role,   { staff: 0, manager: 1, admin: 2 }, prefix: :to

  validates :from_role, presence: true
  validates :to_role,   presence: true
  validates :reason,    presence: true, length: { minimum: 10 }

  # Prevent in-place updates — this record is append-only.
  before_update { raise ActiveRecord::ReadOnlyRecord, 'EmployeeRoleAudit records are immutable' }
  before_destroy { raise ActiveRecord::ReadOnlyRecord, 'EmployeeRoleAudit records are immutable' }

  default_scope { order(created_at: :desc) }
end
