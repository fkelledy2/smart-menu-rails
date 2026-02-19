# frozen_string_literal: true

class LocalGuide < ApplicationRecord
  belongs_to :approved_by_user, class_name: 'User', optional: true

  enum :status, { draft: 0, published: 1, archived: 2 }

  scope :published, -> { where(status: :published) }

  validates :title, :slug, :city, :country, :content, presence: true
  validates :slug, uniqueness: true

  before_validation :generate_slug, on: :create

  private

  def generate_slug
    self.slug ||= "#{city}-#{category}-#{SecureRandom.hex(4)}".parameterize
  end
end
