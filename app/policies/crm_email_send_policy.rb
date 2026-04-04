# frozen_string_literal: true

class CrmEmailSendPolicy < ApplicationPolicy
  def new?    = create?
  def create? = mellow_admin?

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
    user.respond_to?(:admin?) && user.admin? &&
      user.respond_to?(:email) && user.email.to_s.end_with?('@mellow.menu')
  end
end
