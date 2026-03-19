# frozen_string_literal: true

class MenuOptimizationPolicy < ApplicationPolicy
  def index?
    user_owns_restaurant? && (manager_or_above? || owner?)
  end

  def menu_engineering?
    index?
  end

  def pricing_recommendations?
    index?
  end

  def bundling_opportunities?
    index?
  end

  def apply_optimizations?
    user_owns_restaurant? && (manager_or_above? || owner?)
  end

  private

  def user_owns_restaurant?
    record.user_id == user.id
  end

  def manager_or_above?
    employee = record.employees.find_by(user_id: user.id)
    employee&.manager? || employee&.admin?
  end

  def owner?
    record.user_id == user.id
  end
end
