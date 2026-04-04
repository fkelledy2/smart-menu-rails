# frozen_string_literal: true

class CrmLeadPolicy < ApplicationPolicy
  # All CRM actions restricted to mellow.menu admin users only.
  # No restaurant owner, staff, or customer may ever access CRM data.

  def index?       = mellow_admin?
  def show?        = mellow_admin?
  def new?         = create?
  def create?      = mellow_admin?
  def edit?        = update?
  def update?      = mellow_admin?
  def destroy?     = mellow_admin?
  def transition?  = mellow_admin?
  def convert?     = mellow_admin?
  def reopen?      = mellow_admin?

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.all if mellow_admin?

      scope.none
    end

    private

    def mellow_admin?
      user.respond_to?(:super_admin?) && user.super_admin? &&
        user.respond_to?(:email) && user.email.to_s.end_with?('@mellow.menu')
    end
  end

  private

  def mellow_admin?
    user.respond_to?(:super_admin?) && user.super_admin? &&
      user.respond_to?(:email) && user.email.to_s.end_with?('@mellow.menu')
  end
end
