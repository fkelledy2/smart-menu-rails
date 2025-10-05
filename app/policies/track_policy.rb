# frozen_string_literal: true

class TrackPolicy < ApplicationPolicy
  # Tracks are owned by restaurants, which are owned by users
  # Only restaurant owners can manage their tracks
  
  def index?
    user.present?
  end
  
  def show?
    user.present? && owns_track?
  end
  
  def create?
    user.present?
  end
  
  def new?
    create?
  end
  
  def update?
    user.present? && owns_track?
  end
  
  def edit?
    update?
  end
  
  def destroy?
    user.present? && owns_track?
  end
  
  class Scope < Scope
    def resolve
      if user.present?
        # Return tracks from restaurants owned by the user
        scope.joins(:restaurant).where(restaurant: { user: user })
      else
        scope.none
      end
    end
  end
  
  private
  
  def owns_track?
    record.restaurant&.user == user
  end
end
