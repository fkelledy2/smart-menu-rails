class Restaurant < ApplicationRecord
  include ImageUploader::Attachment(:image)
  belongs_to :user

  has_many :tablesettings, dependent: :delete_all
  has_many :menus, dependent: :delete_all
  has_many :employees, dependent: :delete_all
  has_many :taxes, dependent: :delete_all
  has_many :tips, dependent: :delete_all
  has_many :restaurantavailabilities, dependent: :delete_all
  has_many :menusections, through: :menus
  has_many :menuavailabilities, through: :menus
  has_one  :genimage, dependent: :destroy
  has_many :tracks, dependent: :delete_all
  has_many :restaurantlocales, dependent: :delete_all

  # Returns all locale codes for this restaurant
  def locales
    restaurantlocales.pluck(:locale)
  end

  enum status: {
    inactive: 0,
    active: 1,
    archived: 2
  }

  enum wifiEncryptionType: {
    WPA: 0,
    WEP: 1,
    NONE: 2
  }

  def spotifyAuthUrl
    '/auth/spotify?restaurant_id='+self.id.to_s
  end

  def spotifyPlaylistUrl
    '/restaurants/'+self.id.to_s+'/tracks'
  end

  def gen_image_theme
      if( genimage )
          genimage.id
      end
  end

  def total_capacity
    tablesettings.map(&:capacity).sum
  end

  def wifiQRString
    wifiQRString = 'WIFI:S:'
    if wifissid
        wifiQRString.concat(wifissid+';')
    end
    if wifiEncryptionType
        wifiQRString.concat('T:'+wifiEncryptionType+';')
    end
    if wifiPassword
        wifiQRString.concat('P:'+wifiPassword+';')
    end
    if wifiHidden
        wifiQRString.concat('H:true;')
    else
        wifiQRString.concat('H:false;')
    end
  end

  def defaultLocale
    Restaurantlocale.where(restaurant_id: self.id, status: 'active', dfault: true).first
  end

  def getLocale( locale )
    Restaurantlocale.where(restaurant_id: self.id, status: 'active', locale: locale).first
  end

  validates :name, :presence => true
  validates :address1, :presence => false
  validates :city, :presence => false
  validates :postcode, :presence => false
  validates :country, :presence => false
  validates :status, :presence => true
  validates :user, :presence => true
end
