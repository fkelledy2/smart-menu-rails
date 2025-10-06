# frozen_string_literal: true

class Admin::MetricsPolicy < ApplicationPolicy
  # Admin metrics - only admin users can access
  
  def index?
    user.present? && user.admin?
  end
  
  def show?
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
