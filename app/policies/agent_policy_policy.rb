# frozen_string_literal: true

# Pundit policy for AgentPolicy model.
# Restaurant owners can view; only admins can edit in v1.
class AgentPolicyPolicy < ApplicationPolicy
  def index?
    return true if super_admin?

    owner_of_restaurant?
  end

  def show?
    index?
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
      return scope.all if user.respond_to?(:super_admin?) && user.super_admin?

      scope.joins(:restaurant).where(restaurants: { user_id: user.id })
    end
  end

  private

  def owner_of_restaurant?
    return false unless user&.persisted? && record.respond_to?(:restaurant)

    record.restaurant&.user_id == user.id
  end
end
