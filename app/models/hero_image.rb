class HeroImage < ApplicationRecord
  include IdentityCache

  # Enums
  enum :status, {
    unapproved: 0,
    approved: 1,
  }

  # Validations
  validates :image_url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: 'must be a valid URL' }
  validates :sequence, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :status, presence: true

  # Scopes
  scope :approved, -> { where(status: :approved) }
  scope :ordered, -> { order(:sequence, :created_at) }

  # IdentityCache configuration
  cache_index :id
  cache_index :status

  # Class methods
  def self.approved_for_carousel
    approved.ordered
  end
end
