class Smartmenu < ApplicationRecord
  include IdentityCache

  # Standard ActiveRecord associations
  belongs_to :restaurant, touch: true
  belongs_to :menu, optional: true
  belongs_to :tablesetting, optional: true
  has_many :dining_sessions, dependent: :destroy

  # IdentityCache configuration
  cache_index :id
  cache_index :restaurant_id
  cache_index :menu_id
  cache_index :tablesetting_id

  # Cache associations
  cache_belongs_to :restaurant
  cache_belongs_to :menu
  cache_belongs_to :tablesetting

  before_validation :generate_public_token, on: :create

  def menuName
    if menu
      menu.name
    else
      '*'
    end
  end

  def tableSettingName
    if tablesetting
      tablesetting.name
    else
      '*'
    end
  end

  def fqlinkname
    if menu && restaurant
      "#{menu.name} @ #{restaurant.name}"
    else
      restaurant.name
    end
  end

  validates :slug, presence: true
  validates :restaurant, presence: false
  validates :public_token, presence: true, uniqueness: true, length: { is: 64 }, allow_blank: false

  # Rotate the public_token, invalidating the old QR code.
  # Deactivates all active DiningSessions for this smartmenu.
  def rotate_token!
    DiningSession.where(smartmenu_id: id, active: true).update_all(active: false)
    update!(public_token: SecureRandom.hex(32))
  end

  private

  def generate_public_token
    self.public_token ||= SecureRandom.hex(32)
  end
end
