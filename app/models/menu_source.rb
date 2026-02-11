require 'cgi'
require 'uri'

class MenuSource < ApplicationRecord
  enum :source_type, {
    html: 0,
    pdf: 1,
  }

  enum :status, {
    active: 0,
    disabled: 1,
  }

  belongs_to :restaurant, optional: true
  belongs_to :discovered_restaurant, optional: true

  has_one_attached :latest_file
  has_many :menu_source_change_reviews, dependent: :destroy

  def derived_menu_name
    raw = if latest_file.attached?
      latest_file.filename.to_s
    else
      begin
        File.basename(URI.parse(source_url.to_s).path.to_s)
      rescue StandardError
        nil
      end
    end

    raw = raw.to_s
    raw = raw.sub(/\.[a-z0-9]{2,8}\z/i, '')
    raw = CGI.unescape(raw)
    raw = raw.tr('_-', ' ')
    raw = raw.gsub(/\b(menu|menus|pdf|download)\b/i, ' ')
    raw = raw.gsub(/\s+/, ' ').strip

    raw.presence || 'Menu'
  rescue StandardError
    'Menu'
  end

  validates :source_url, presence: true
  validates :source_type, presence: true
  validates :status, presence: true
end
