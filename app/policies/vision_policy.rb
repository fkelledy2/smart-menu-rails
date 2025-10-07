# frozen_string_literal: true

class VisionPolicy < ApplicationPolicy
  def analyze?
    # Allow authenticated users to use vision analysis
    user.present?
  end

  def detect_menu_items?
    # Allow authenticated users to detect menu items
    user.present?
  end
end
