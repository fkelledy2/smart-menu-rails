# frozen_string_literal: true

class Admin::PerformancePolicy < ApplicationPolicy
  # Performance monitoring - only admin users can access

  def index?
    user.present? && user.admin?
  end

  def show?
    user.present? && user.admin?
  end

  def requests?
    user.present? && user.admin?
  end

  def queries?
    user.present? && user.admin?
  end

  def cache?
    user.present? && user.admin?
  end

  def memory?
    user.present? && user.admin?
  end

  def reset?
    user.present? && user.admin?
  end

  def export?
    user.present? && user.admin?
  end

  class Scope < Scope
    def resolve
      if user.present? && user.admin?
        scope.all
      else
        scope.none
      end
    end
  end
end
