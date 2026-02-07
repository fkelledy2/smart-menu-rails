class UserplanPolicy < ApplicationPolicy
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

  def start_plan_change?
    update?
  end

  def portal_plan_changed?
    update?
  end

  def destroy?
    owner?
  end

  class Scope < Scope
    def resolve
      scope.where(user: user)
    end
  end

  private

  def owner?
    return false unless user && record.respond_to?(:user)

    record.user_id == user.id
  end
end
