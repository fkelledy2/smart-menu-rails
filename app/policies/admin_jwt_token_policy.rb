# frozen_string_literal: true

class AdminJwtTokenPolicy < ApplicationPolicy
  # All actions restricted to users with admin:true AND a @mellow.menu email.
  # This is stricter than plain admin? because JWT tokens grant API access
  # to live restaurant data — only mellow.menu staff should issue them.

  def index?
    mellow_admin?
  end

  def show?
    mellow_admin?
  end

  def new?
    create?
  end

  def create?
    mellow_admin?
  end

  def edit?
    update?
  end

  def update?
    mellow_admin?
  end

  def destroy?
    false # Tokens are never hard-deleted; use revoke
  end

  def revoke?
    mellow_admin?
  end

  def send_email?
    mellow_admin?
  end

  def download_link?
    mellow_admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.all if mellow_admin?

      scope.none
    end

    private

    def mellow_admin?
      user.respond_to?(:admin?) && user.admin? &&
        user.respond_to?(:email) && user.email.to_s.end_with?('@mellow.menu')
    end
  end

  private

  def mellow_admin?
    user.respond_to?(:admin?) && user.admin? &&
      user.respond_to?(:email) && user.email.to_s.end_with?('@mellow.menu')
  end
end
