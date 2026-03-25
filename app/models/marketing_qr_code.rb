# frozen_string_literal: true

class MarketingQrCode < ApplicationRecord
  belongs_to :restaurant,  optional: true
  belongs_to :menu,        optional: true
  belongs_to :tablesetting, optional: true
  belongs_to :smartmenu, optional: true
  belongs_to :created_by_user, class_name: 'User'

  enum :status, { unlinked: 0, linked: 1, archived: 2 }

  validates :token,              presence: true, uniqueness: true
  validates :status,             presence: true

  # token is immutable once set
  attr_readonly :token

  before_validation :generate_token, on: :create

  scope :active, -> { where.not(status: :archived) }

  # The publicly encoded URL for this QR code — never changes.
  def public_url(host: 'mellow.menu', protocol: 'https')
    "#{protocol}://#{host}/m/#{token}"
  end

  # Effective holding destination when unlinked.
  def effective_holding_url
    holding_url.presence || 'https://mellow.menu'
  end

  private

  def generate_token
    self.token ||= SecureRandom.uuid
  end
end
