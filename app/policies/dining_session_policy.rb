class DiningSessionPolicy < ApplicationPolicy
  # DiningSessions are created by the public-facing QR flow — no auth required.
  def create?
    true
  end

  # Only the restaurant owner or super_admin may view individual sessions.
  def show?
    return true if super_admin?

    owner?
  end

  # Only the restaurant owner or super_admin may list sessions (admin view).
  def index?
    return true if super_admin?

    owner?
  end

  # Invalidation is an admin/owner operation.
  def destroy?
    return true if super_admin?

    owner?
  end

  class Scope < Scope
    def resolve
      return scope.all if user.respond_to?(:super_admin?) && user.super_admin?

      scope.joins(:restaurant).where(restaurants: { user_id: user.id })
    end
  end

  private

  def owner?
    return false unless user && record.respond_to?(:restaurant)

    record.restaurant&.user_id == user.id
  end
end
