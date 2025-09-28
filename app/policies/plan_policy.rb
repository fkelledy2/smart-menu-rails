class PlanPolicy < ApplicationPolicy
  def index?
    true # Public viewing of plans
  end

  def show?
    true # Public viewing of plans
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
      # Plans are public
      scope.all
    end
  end
end
