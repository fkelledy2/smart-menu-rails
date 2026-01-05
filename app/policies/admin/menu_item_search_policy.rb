# frozen_string_literal: true

class Admin::MenuItemSearchPolicy < ApplicationPolicy
  def index?
    user.present? && user.admin?
  end

  def reindex?
    user.present? && user.admin?
  end
end
