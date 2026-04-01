# frozen_string_literal: true

class PricingModelPolicy < ApplicationPolicy
  def index?
    super_admin?
  end

  def show?
    super_admin?
  end

  def new?
    super_admin?
  end

  def create?
    super_admin?
  end

  def edit?
    super_admin? && record.draft?
  end

  def update?
    super_admin? && record.draft?
  end

  def preview?
    super_admin?
  end

  def publish?
    super_admin? && record.draft?
  end

  def destroy?
    super_admin? && record.draft?
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
