class RestaurantRemovalRequest < ApplicationRecord
  enum :source, {
    public_page: 0,
    email: 1,
  }

  enum :status, {
    received: 0,
    actioned_unpublished: 1,
    resolved: 2,
  }

  belongs_to :restaurant
  belongs_to :actioned_by_user, class_name: 'User', optional: true

  validates :requested_by_email, presence: true, format: { with: /\A[^\s@]+@[^\s@]+\.[^\s@]+\z/ }
  validates :source, presence: true
  validates :status, presence: true
  validates :reason, presence: true

  # Immediately unpublish the restaurant and mark the request as actioned.
  def action_unpublish!(user:)
    transaction do
      restaurant.update!(preview_enabled: false)
      update!(
        status: :actioned_unpublished,
        actioned_at: Time.current,
        actioned_by_user: user,
      )
    end
  end
end
