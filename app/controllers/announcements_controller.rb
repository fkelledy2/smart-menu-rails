class AnnouncementsController < ApplicationController
  before_action :authenticate_user!
  before_action :mark_as_read, if: :user_signed_in?

  # Pundit authorization
  after_action :verify_policy_scoped, only: [:index]

  def index
    @announcements = policy_scope(Announcement).order(published_at: :desc)
  end

  private

  def mark_as_read
    current_user.update(announcements_last_read_at: Time.zone.now)
  end
end
