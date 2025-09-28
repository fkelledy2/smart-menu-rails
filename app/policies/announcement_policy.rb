class AnnouncementPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    user.present?
  end

  class Scope < Scope
    def resolve
      # Announcements are global - all users can see all announcements
      scope.all
    end
  end
end
