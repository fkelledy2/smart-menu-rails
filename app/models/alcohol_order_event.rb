class AlcoholOrderEvent < ApplicationRecord
  belongs_to :ordr
  belongs_to :ordritem
  belongs_to :menuitem
  belongs_to :restaurant

  validates :abv, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true

  scope :acknowledged, -> { where(age_check_acknowledged: true) }
  scope :unacknowledged, -> { where(age_check_acknowledged: false) }
end
