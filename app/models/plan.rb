class Plan < ApplicationRecord
  enum :status, {
    inactive: 0,
    active: 1,
  }

  enum :action, {
    register: 0,
    call: 1,
  }
  
  # Virtual attribute for name (uses key)
  def name
    case key
    when 'plan.starter.key'
      'Starter'
    when 'plan.pro.key'
      'Professional'
    when 'plan.business.key'
      'Business'
    when 'plan.enterprise.key'
      'Enterprise'
    else
      key&.humanize
    end
  end
  
  def price
    pricePerMonth
  end

  def getLanguages
    if languages == -1
      'Unlimited'
    else
      languages
    end
  end

  def getLocations
    if locations == -1
      'Unlimited'
    else
      locations
    end
  end

  def getItemsPerMenu
    if itemspermenu == -1
      'Unlimited'
    else
      itemspermenu
    end
  end

  def getMenusPerLocation
    if menusperlocation == -1
      'Unlimited'
    else
      menusperlocation
    end
  end
end
