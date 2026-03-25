class Ordrparticipant < ApplicationRecord
  include IdentityCache

  # Standard ActiveRecord associations
  belongs_to :employee, optional: true
  belongs_to :ordr, optional: false
  belongs_to :ordritem, optional: true
  has_many :ordrparticipant_allergyn_filters, dependent: :destroy
  has_many :allergyns, through: :ordrparticipant_allergyn_filters

  # Enums
  enum :role, {
    customer: 0,
    staff: 1,
  }

  # Validations
  validates :sessionid, presence: true
  validates :preferredlocale, presence: false

  # IdentityCache configuration
  cache_index :id
  cache_index :employee_id
  cache_index :ordr_id
  cache_index :ordritem_id

  # Cache associations
  # Note: Cannot cache through associations (has_many :through) with IdentityCache
  # Only caching direct associations
  cache_belongs_to :employee
  cache_belongs_to :ordr
  cache_belongs_to :ordritem
  cache_has_many :ordrparticipant_allergyn_filters, embed: :ids

  # Allergyns are accessed through ordrparticipant_allergyn_filters
  # This is a has_many :through association which can't be directly cached

  # Normalize locale to lowercase before save (I18n expects :en, :it, not :EN, :IT)
  before_save :normalize_locale
  # Floorplan real-time tile update when participant count changes
  after_commit :broadcast_floorplan_tile_update, on: %i[create destroy]

  private

  def normalize_locale
    self.preferredlocale = preferredlocale.downcase if preferredlocale.present?
  end

  def broadcast_floorplan_tile_update
    return unless ordr&.tablesetting_id && ordr.restaurant_id

    FloorplanBroadcastService.broadcast_tile(
      tablesetting_id: ordr.tablesetting_id,
      restaurant_id: ordr.restaurant_id,
    )
  rescue StandardError => e
    Rails.logger.warn(
      "[Ordrparticipant#broadcast_floorplan_tile_update] Failed for ordrparticipant=#{id}: #{e.class}: #{e.message}",
    )
  end
end
