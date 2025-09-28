class TestimonialPolicy < ApplicationPolicy
  def index?
    user.present? && user.admin? # Admin only
  end

  def show?
    user.present?
  end

  def create?
    user.present?
  end

  def update?
    owner? || (user.present? && user.admin?)
  end

  def destroy?
    owner? || (user.present? && user.admin?)
  end

  class Scope < Scope
    def resolve
      if user.admin?
        scope.all
      else
        scope.where(user: user)
      end
    end
  end

  private

  def owner?
    return false unless user && record.respond_to?(:user)

    record.user_id == user.id
  end
end
