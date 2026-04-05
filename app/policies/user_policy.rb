# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  # A user may manage their own 2FA, or a platform super_admin may manage any user's.
  def manage_two_factor?
    return true if super_admin?

    user.persisted? && record.id == user.id
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.all if user.respond_to?(:super_admin?) && user.super_admin?

      scope.where(id: user.id)
    end
  end
end
