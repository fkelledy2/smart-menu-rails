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
    case locale&.upcase
    when 'IT'
      'https://flagcdn.com/w40/it.png'
    when 'FR'
      'https://flagcdn.com/w40/fr.png'
    when 'ES'
      'https://flagcdn.com/w40/es.png'
    else
      'https://flagcdn.com/w40/gb.png'
    end
  end

  def language
    case locale&.upcase
    when 'IT'
      'Italian'
    when 'FR'
      'French'
    when 'ES'
      'Spanish'
    else
      'English'
    end
  end
end
