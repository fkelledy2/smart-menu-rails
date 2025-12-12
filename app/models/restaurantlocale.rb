class Restaurantlocale < ApplicationRecord
  include IdentityCache

  # Standard ActiveRecord associations
  belongs_to :restaurant

  # Enums
  enum :status, {
    inactive: 0,
    active: 1,
    archived: 2,
  }

  # IdentityCache configuration
  cache_index :id
  cache_index :restaurant_id

  # Cache associations
  cache_belongs_to :restaurant

  def flag
    code = locale.to_s.split(/[-_]/).first.upcase
    case code
    when 'IT'
      'https://flagcdn.com/w40/it.png'
    when 'FR'
      'https://flagcdn.com/w40/fr.png'
    when 'ES'
      'https://flagcdn.com/w40/es.png'
    when 'PT'
      'https://flagcdn.com/w40/pt.png'
    else
      'https://flagcdn.com/w40/gb.png'
    end
  end

  def language
    code = locale.to_s.split(/[-_]/).first.upcase
    case code
    when 'IT'
      'Italian'
    when 'FR'
      'French'
    when 'ES'
      'Spanish'
    when 'PT'
      'Portuguese'
    else
      'English'
    end
  end
end
