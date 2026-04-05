# frozen_string_literal: true

# Tags are admin read-only via UI.
# Create/update/destroy is restricted to internal services only.
class CrmLeadTagPolicy < ApplicationPolicy
  def index?  = mellow_admin?
  def show?   = mellow_admin?
  def create? = false
  def update? = false
  def destroy? = false

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
