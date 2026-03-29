# frozen_string_literal: true

# Pundit policy for partner integration resources.
# The record is the restaurant whose integrations are being accessed.
class PartnerIntegrationPolicy < ApplicationPolicy
  # Read signals via the workforce endpoint
  def workforce?
    api_jwt_owner? || owner? || employee_admin?
  end

  # Read signals via the CRM endpoint
  def crm?
    api_jwt_owner? || owner? || employee_admin?
  end

  # View dead-letter error logs (admin-only or owner)
  def error_logs?
    super_admin? || owner?
  end

  class Scope < Scope
    def resolve
      return scope.all if user.respond_to?(:super_admin?) && user.super_admin?

      owned_ids = scope.where(user: user).pluck(:id)
      return scope.none if owned_ids.empty?

      scope.where(id: owned_ids)
    end
  end

  private

  # True when the request is authenticated via an admin-issued JWT token.
  # The scope enforcement is handled separately via enforce_scope! in the controller.
  def api_jwt_owner?
    # user here is the admin who minted the token; we trust the controller to
    # have already enforced the required scope before the Pundit check runs.
    user.respond_to?(:super_admin?) && user.super_admin?
  end

  def owner?
    return false unless user && record

    record.user_id == user.id
  end

  def employee_admin?
    return false unless user.present? && record

    user.respond_to?(:admin_employee_for_restaurant?) &&
      user.admin_employee_for_restaurant?(record.id)
  end
end
