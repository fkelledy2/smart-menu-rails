# frozen_string_literal: true

class MenuExperimentPolicy < ApplicationPolicy
  # Restaurant owners, admins, and managers can manage experiments.
  # Experiments are restricted to Pro+ plan tiers.

  def index?
    return true if super_admin?

    can_manage? && on_eligible_plan?
  end

  def show?
    return true if super_admin?

    can_manage? && on_eligible_plan?
  end

  def create?
    return true if super_admin?

    can_manage? && on_eligible_plan?
  end

  def new?
    create?
  end

  def update?
    return true if super_admin?

    can_manage? && on_eligible_plan?
  end

  def edit?
    update?
  end

  def destroy?
    return true if super_admin?

    can_manage? && on_eligible_plan?
  end

  def pause?
    update?
  end

  def end_experiment?
    update?
  end

  class Scope < Scope
    def resolve
      return scope.all if user.respond_to?(:super_admin?) && user.super_admin?
      return scope.none if user.blank?

      # Return experiments for menus belonging to restaurants the user can access
      owned_restaurant_ids = Restaurant.where(user_id: user.id).select(:id)
      employee_restaurant_ids = Employee.where(user: user, status: :active).select(:restaurant_id)

      menu_ids = Menu
        .left_joins(:restaurant_menus)
        .where(
          'menus.restaurant_id IN (?) OR restaurant_menus.restaurant_id IN (?)',
          owned_restaurant_ids,
          employee_restaurant_ids,
        )
        .select(:id)
        .distinct

      scope.where(menu_id: menu_ids)
    end
  end

  private

  def restaurant
    return @restaurant if defined?(@restaurant)

    @restaurant = if record.is_a?(MenuExperiment) && record.menu_id.present?
                    record.menu&.restaurant
                  end
  end

  def can_manage?
    return false if user.blank?

    # Class-level authorization (e.g. authorize MenuExperiment in index/new/create)
    # cannot resolve a specific restaurant from the record. Allow any eligible user;
    # Pundit scopes restrict the actual data returned.
    return true if record.is_a?(Class)

    return false if restaurant.blank?

    owner? || employee_admin? || employee_manager?
  end

  def owner?
    restaurant&.user_id == user.id
  end

  def employee_admin?
    user.admin_employee_for_restaurant?(restaurant.id)
  end

  def employee_manager?
    user.manager_employee_for_restaurant?(restaurant.id)
  end

  ELIGIBLE_PLAN_KEYS = %w[plan.pro.key plan.business.key].freeze

  def on_eligible_plan?
    user.plan&.key.in?(ELIGIBLE_PLAN_KEYS) || super_admin?
  end
end
