class EmployeeRoleChangedJob < ApplicationJob
  queue_as :default

  # Deliver the role-change notification email.
  # Accepts the EmployeeRoleAudit id so the job is safely serialisable.
  def perform(employee_role_audit_id)
    audit = EmployeeRoleAudit.find_by(id: employee_role_audit_id)
    return unless audit

    EmployeeMailer.role_changed(audit).deliver_now
  end
end
