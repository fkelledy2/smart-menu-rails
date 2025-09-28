class AllergynPolicy < ApplicationPolicy
  def index?
    true # Public viewing allowed
  end

  def show?
    owner?
  end

  def create?
    user.present?
  end

  def update?
    owner?
  end

  def destroy?
    owner?
  end

  class Scope < Scope
    def resolve
      scope.joins(:restaurant).where(restaurants: { user_id: user.id })
    end
  end

  private

  def owner?
    return false unless user && record.respond_to?(:restaurant)

    record.restaurant&.user_id == user.id
  end
end
