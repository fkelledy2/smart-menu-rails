# frozen_string_literal: true

class Admin::HerokuInventoryPolicy < ApplicationPolicy
  def index?
    super_admin?
  end

  def show?
    super_admin?
  end

  def coefficients?
    super_admin?
  end

  def update_coefficients?
    super_admin?
  end

  def trigger_snapshot?
    super_admin?
  end

  def trigger_rollup?
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
