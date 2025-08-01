class Plan < ApplicationRecord

  enum status: {
    inactive: 0,
    active: 1,
  }

  enum action: {
    register: 0,
    call: 1,
  }

  def getLanguages
      if languages != -1
          languages
      else
          "Unlimited"
      end
  end

  def getLocations
      if locations != -1
          locations
      else
          "Unlimited"
      end
  end

  def getItemsPerMenu
      if itemspermenu != -1
          itemspermenu
      else
          "Unlimited"
      end
  end
  def getMenusPerLocation
      if menusperlocation != -1
          menusperlocation
      else
          "Unlimited"
      end
  end
end
