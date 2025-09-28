class FeaturePolicy < ApplicationPolicy
  def index?
    true # Public viewing of features
  end

  def show?
    true # Public viewing of features
  end

  def create?
    user.present? && user.admin? # Admin only
  end

  def update?
    user.present? && user.admin? # Admin only
  end

  def destroy?
    user.present? && user.admin? # Admin only
  end

  class Scope < Scope
    def resolve
      # Features are public
      scope.all
    end
  end
end
