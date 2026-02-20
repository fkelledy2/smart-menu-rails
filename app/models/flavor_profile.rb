# frozen_string_literal: true

class FlavorProfile < ApplicationRecord
  belongs_to :profilable, polymorphic: true

  validates :profilable_type, presence: true
  validates :profilable_id, uniqueness: { scope: :profilable_type }

  CONTROLLED_TAGS = %w[
    sweet smoke_peat spice vanilla_oak dried_fruit citrus floral
    nutty saline umami bitter creamy tannic herbal earthy
    tropical stone_fruit berry chocolate caramel honey
  ].freeze

  STRUCTURE_KEYS = %w[
    alcohol_intensity body sweetness_level finish_length
    peat_level acidity tannin
  ].freeze

  scope :for_products, -> { where(profilable_type: 'Product') }
  scope :for_menuitems, -> { where(profilable_type: 'Menuitem') }

  def tag_list
    tags.join(', ')
  end
end
