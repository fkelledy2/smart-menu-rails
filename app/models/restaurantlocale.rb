class Restaurantlocale < ApplicationRecord
  belongs_to :restaurant

  enum status: {
    inactive: 0,
    active: 1,
    archived: 2
  }

  def flag
    if locale == 'IT'
        "https://flagcdn.com/w40/it.png"
    else
        if locale == 'FR'
            "https://flagcdn.com/w40/fr.png"
        else
            if locale == 'ES'
                "https://flagcdn.com/w40/es.png"
            else
                "https://flagcdn.com/w40/gb.png"
            end
        end
    end
  end

  def language
    if locale == 'IT'
        "Italian"
    else
        if locale == 'FR'
            "French"
        else
            if locale == 'ES'
                "Spanish"
            else
                "English"
            end
        end
    end
  end

end
