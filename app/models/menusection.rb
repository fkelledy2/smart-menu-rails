class Menusection < ApplicationRecord
  # Responsive image helpers
  def image_url_or_fallback(size = nil)
    if image_attacher.derivatives&.key?(size)
      image_url(size)
    else
      image_url # fallback to original
    end
  end
  def thumb_url
    image_url_or_fallback(:thumb)
  end

  def medium_url
    image_url_or_fallback(:medium)
  end

  def large_url
    image_url_or_fallback(:large)
  end

  def image_srcset
    [
      "#{thumb_url} 200w",
      "#{medium_url} 600w",
      "#{large_url} 1000w"
    ].join(', ')
  end

  def image_sizes
    '(max-width: 600px) 200px, (max-width: 1200px) 600px, 1000px'
  end
  include ImageUploader::Attachment(:image)
  include Localisable

  localisable locale_model: 'Menusectionlocale', locale_foreign_key: :menusection_id, parent_chain: ->(section) { section.menu }
  belongs_to :menu
  has_many :menuitems
  has_one :genimage, dependent: :destroy

  enum status: {
    inactive: 0,
    active: 1,
    archived: 2
  }
  def gen_image_theme
      if( genimage )
          genimage.id
      end
  end

  def fromOffset
      (fromhour*60)+frommin
  end
  def toOffset
      (tohour*60)+tomin
  end


  validates :name, :presence => true
  validates :menu, :presence => true
  validates :status, :presence => true
end
