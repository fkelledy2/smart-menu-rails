class HeroImagePolicy < ApplicationPolicy
  def index?
    user.present? && user.admin? # Admin only
  end

  def show?
    user.present? && user.admin?
  end

  def create?
    user.present? && user.admin?
  end

  def update?
    user.present? && user.admin?
  end

  def destroy?
    user.present? && user.admin?
  end

  def clear_cache?
    user.present? && user.admin?
  end

  class Scope < Scope
    def resolve
      if user&.admin?
        scope.all
      else
        scope.none # Non-admins can't access hero images management
      end
    end
  end
end
