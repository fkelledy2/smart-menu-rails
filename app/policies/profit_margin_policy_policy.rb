# frozen_string_literal: true

class ProfitMarginPolicyPolicy < ApplicationPolicy
  def index?
    super_admin?
  end

  def create?
    super_admin?
  end

  def update?
    super_admin?
  end

  def destroy?
    super_admin?
  end

  class Scope < Scope
    def resolve
      return scope.none unless user.present? && user.admin? && user.super_admin?

      scope.all
    end
  end

  private

  def super_admin?
    user.present? && user.admin? && user.super_admin?
  end
end
