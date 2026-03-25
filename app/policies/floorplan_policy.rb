# frozen_string_literal: true

# FloorplanPolicy: controls access to the real-time table floorplan dashboard.
# Only restaurant owners and active employees may view the dashboard.
# Customers (anonymous or authenticated) are never permitted.
class FloorplanPolicy < ApplicationPolicy
  # record is the Restaurant instance (authorize :restaurant, policy_class: FloorplanPolicy)
  def show?
    return false unless user.present? && user.persisted?

    owner? || active_employee?
  end

  private

  def owner?
    record.respond_to?(:user_id) && record.user_id == user.id
  end

  def active_employee?
    return false unless record.respond_to?(:id)

    user.active_employee_for_restaurant?(record.id)
  end
end
