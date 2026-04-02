# frozen_string_literal: true

class AgentArtifactPolicy < ApplicationPolicy
  def index?
    return true if super_admin?

    owner_or_manager?
  end

  def show?
    return true if super_admin?

    owner_or_manager?
  end

  # Only restaurant owners and admins can approve/reject artifacts.
  def approve?
    return true if super_admin?

    owner_of_restaurant?
  end

  def reject?
    approve?
  end

  class Scope < Scope
    def resolve
      return scope.all if user.respond_to?(:super_admin?) && user.super_admin?

      scope.joins(agent_workflow_run: :restaurant).where(restaurants: { user_id: user.id })
    end
  end

  private

  def owner_or_manager?
    return false unless user&.persisted? && record.respond_to?(:agent_workflow_run)

    restaurant = record.agent_workflow_run.restaurant
    return true if restaurant.user_id == user.id

    user.employees.exists?(restaurant_id: restaurant.id, role: %w[manager admin])
  end

  def owner_of_restaurant?
    return false unless user&.persisted? && record.respond_to?(:agent_workflow_run)

    record.agent_workflow_run.restaurant.user_id == user.id
  end
end
