class RestaurantClaimRequest < ApplicationRecord
  enum :status, {
    started: 0,
    soft_verified: 1,
    stripe_kyc_started: 2,
    stripe_kyc_completed: 3,
    approved: 4,
    rejected: 5,
  }

  enum :verification_method, {
    email_domain: 0,
    dns_txt: 1,
    gmb: 2,
    manual_upload: 3,
  }

  belongs_to :restaurant
  belongs_to :initiated_by_user, class_name: 'User', optional: true
  belongs_to :reviewed_by_user, class_name: 'User', optional: true

  validates :claimant_email, presence: true, format: { with: /\A[^\s@]+@[^\s@]+\.[^\s@]+\z/ }
  validates :status, presence: true
  validates :verification_method, presence: true

  # Approve the claim: transition restaurant to soft_claimed and link the user.
  def approve!(reviewer:)
    transaction do
      update!(
        status: :approved,
        verified_at: Time.current,
        reviewed_by_user: reviewer,
      )
      restaurant.update!(claim_status: :soft_claimed)
    end
  end

  def reject!(reviewer:, notes: nil)
    update!(
      status: :rejected,
      reviewed_by_user: reviewer,
      review_notes: notes,
    )
  end
end
