class MenuparticipantPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    return true unless user # Allow anonymous customers

    owner?
  end

  def create?
    return true unless user # Allow anonymous customers

    user.present?
  end

  def update?
    return true unless user # Allow anonymous customers

    owner?
  end

  def destroy?
    owner?
  end

  class Scope < Scope
    def resolve
      scope.joins(smartmenu: :restaurant).where(restaurants: { user_id: user.id })
    end
  end

  private

  def owner?
    return false unless user && record.respond_to?(:smartmenu)

    record.smartmenu&.restaurant&.user_id == user.id
  end
end
