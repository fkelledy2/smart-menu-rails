# frozen_string_literal: true

class AgentWorkflowRunPolicy < ApplicationPolicy
  # Restaurant owner or manager can view their own workflow runs.
  def index?
    return true if super_admin?

    owner_or_manager?
  end

  def show?
    return true if super_admin?

    owner_of_run?
  end

  def create?
    return true if super_admin?

    owner_of_restaurant?
  end

  def destroy?
    super_admin?
  end

  class Scope < Scope
    def resolve
      return scope.all if user.respond_to?(:super_admin?) && user.super_admin?

      scope.joins(:restaurant).where(restaurants: { user_id: user.id })
    end
  end

  private

  def owner_or_manager?
    return false unless user&.persisted?

    owner_of_restaurant? || manager_of_restaurant?
  end

  def owner_of_run?
    return false unless user&.persisted? && record.respond_to?(:restaurant)

    record.restaurant&.user_id == user.id || manager_of_restaurant?
  end

  def owner_of_restaurant?
    return false unless user&.persisted? && record.respond_to?(:restaurant)

    record.restaurant&.user_id == user.id
  end

  def manager_of_restaurant?
    return false unless user&.persisted? && record.respond_to?(:restaurant)

    restaurant_id = record.restaurant_id
    user.employees.exists?(restaurant_id: restaurant_id, role: %w[manager admin])
  end
end
