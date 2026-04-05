# frozen_string_literal: true

# CopilotPolicy — authorises access to the Staff Copilot endpoints.
#
# query?   — any authenticated restaurant user (owner, manager, admin, staff)
# confirm? — any authenticated restaurant user; individual tool constraints
#             are enforced inside StaffCopilotConfirmService
#
# The record is always the Restaurant.
class CopilotPolicy < ApplicationPolicy
  # Any authenticated user who belongs to this restaurant may query the copilot.
  def query?
    return true if super_admin?

    restaurant_member?
  end

  # Same access gate for the confirm endpoint.
  # Fine-grained role checks happen inside StaffCopilotConfirmService.
  def confirm?
    query?
  end

  private

  def restaurant_member?
    return false unless user&.persisted?

    restaurant = record

    # Owner
    return true if restaurant.user_id == user.id

    # Active employee of any role
    user.employees.exists?(restaurant_id: restaurant.id, status: 'active')
  end
end
