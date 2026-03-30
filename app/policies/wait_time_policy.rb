# frozen_string_literal: true

# WaitTimePolicy: controls access to the wait time dashboard and queue management.
# Only restaurant owners and active employees may view or manage the wait queue.
# record is the Restaurant instance (authorize :restaurant, policy_class: WaitTimePolicy).
class WaitTimePolicy < ApplicationPolicy
  def show?
    staff_or_owner?
  end

  def create_queue_entry?
    staff_or_owner?
  end

  def seat_queue_entry?
    staff_or_owner?
  end

  def no_show_queue_entry?
    staff_or_owner?
  end

  def cancel_queue_entry?
    staff_or_owner?
  end

  private

  def staff_or_owner?
    return false unless user.present? && user.persisted?

    owner? || active_employee?
  end

  def owner?
    record.respond_to?(:user_id) && record.user_id == user.id
  end

  def active_employee?
    return false unless record.respond_to?(:id)

    user.active_employee_for_restaurant?(record.id)
  end
end
