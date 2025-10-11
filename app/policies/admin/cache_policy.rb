# frozen_string_literal: true

class Admin::CachePolicy < ApplicationPolicy
  # Admin cache management - only admin users can access

  def index?
    user.present? && user.admin?
  end

  def stats?
    user.present? && user.admin?
  end

  def warm?
    user.present? && user.admin?
  end

  def clear?
    user.present? && user.admin?
  end

  def reset_stats?
    user.present? && user.admin?
  end

  def health?
    user.present? && user.admin?
  end

  def keys?
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
