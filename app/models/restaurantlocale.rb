class Restaurantlocale < ApplicationRecord
  belongs_to :restaurant

  enum status: {
    inactive: 0,
    active: 1,
    archived: 2
  }

  def getLanguage
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
