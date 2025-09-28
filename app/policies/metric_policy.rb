class MetricPolicy < ApplicationPolicy
  def index?
    user.present? # Admin/system metrics
  end

  def show?
    user.present?
  end

  def create?
    user.present?
  end

  def update?
    user.present?
  end

  def destroy?
    user.present?
  end

  class Scope < Scope
    def resolve
      # System metrics - available to all authenticated users
      scope.all
    end
  end
end
