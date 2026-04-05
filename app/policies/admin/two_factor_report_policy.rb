# frozen_string_literal: true

module Admin
  class TwoFactorReportPolicy < ApplicationPolicy
    def index?
      super_admin?
    end
  end
end
