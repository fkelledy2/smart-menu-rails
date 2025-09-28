class RestaurantPolicy < ApplicationPolicy
  def index?
    user.present?
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

  def spotify_auth?
    owner?
  end

  def spotify_callback?
    owner?
  end

  class Scope < Scope
    def resolve
      scope.where(user: user)
    end
  end

  private

  def owner?
    return false unless user && record
    record.user_id == user.id
  end
end
