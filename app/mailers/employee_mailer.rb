class EmployeeMailer < ApplicationMailer
  # Notify an employee that their role has changed.
  # @param audit [EmployeeRoleAudit]
  def role_changed(audit)
    @audit      = audit
    @employee   = audit.employee
    @restaurant = audit.restaurant
    @changed_by = audit.changed_by
    @from_role  = audit.from_role
    @to_role    = audit.to_role

    recipient_email = @employee.user&.email
    return if recipient_email.blank?

    mail(
      to: recipient_email,
      subject: t('employee_mailer.role_changed.subject', restaurant: @restaurant.name),
    )
  end
end
