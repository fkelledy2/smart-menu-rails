# frozen_string_literal: true

class HerokuAppInventorySnapshotPolicy < ApplicationPolicy
  def index?
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
