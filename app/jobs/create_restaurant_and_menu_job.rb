class CreateRestaurantAndMenuJob < ApplicationJob
  queue_as :default

  def perform(user_id, onboarding_session_id)
    user = User.find(user_id)
    onboarding = OnboardingSession.find(onboarding_session_id)

    ActiveRecord::Base.transaction do
      # Create restaurant
      restaurant = create_restaurant(user, onboarding)

      # Create menu with items
      menu = create_menu(restaurant, onboarding)

      # Update onboarding session
      onboarding.update!(
        restaurant: restaurant,
        menu: menu,
        status: :completed,
      )

      # Track analytics events
      track_completion_analytics(user, restaurant, menu, onboarding)

      # Generate smart menus for the restaurant
      SmartMenuSyncJob.perform_async(restaurant.id)

      # Log success
      Rails.logger.info "Successfully created restaurant #{restaurant.id} and menu #{menu.id} for user #{user.id}"
    end
  rescue StandardError => e
    Rails.logger.error "Failed to create restaurant and menu for user #{user_id}: #{e.message}"
    raise e
  end

  private

  def track_completion_analytics(user, restaurant, menu, _onboarding)
    # Track onboarding completion
    AnalyticsService.track_onboarding_completed(user, {
      restaurant_id: restaurant.id,
      menu_id: menu.id,
      restaurant_name: restaurant.name,
      menu_name: menu.name,
    },)

    # Track restaurant creation
    AnalyticsService.track_restaurant_created(user, restaurant)

    # Track menu creation
    AnalyticsService.track_menu_created(user, menu)

    # Identify user with updated traits
    AnalyticsService.identify_user(user, {
      has_restaurant: true,
      has_menu: true,
      onboarding_completed: true,
      onboarding_completed_at: Time.current,
    },)
  rescue StandardError => e
    Rails.logger.error "Analytics tracking failed in CreateRestaurantAndMenuJob: #{e.message}"
    # Don't fail the job if analytics fails
  end

  def create_restaurant(user, onboarding)
    restaurant = user.restaurants.create!(
      name: onboarding.restaurant_name,
      description: "#{onboarding.restaurant_type&.humanize} restaurant serving #{onboarding.cuisine_type&.humanize} cuisine",
      address1: onboarding.location,
      # Set sensible defaults
      currency: detect_currency_from_location(onboarding.location),
      archived: false,
      status: 1, # active
      capacity: 50, # default capacity
      allowOrdering: true, # enable ordering for restaurant
    )

    # Create default settings
    create_default_restaurant_settings(restaurant)

    # Create employee record for the restaurant owner
    create_owner_employee(restaurant, user)

    restaurant
  end

  def create_menu(restaurant, onboarding)
    menu = restaurant.menus.create!(
      name: onboarding.menu_name || 'Demo Menu',
      status: 1, # active
      archived: false,
      allowOrdering: true, # enable ordering for menu
    )

    # Create menu items from wizard data
    create_menu_items(menu, onboarding.menu_items)

    # Create menu availabilities matching restaurant opening times
    create_menu_availabilities(menu)

    menu
  end

  def create_menu_items(menu, items_data)
    return if items_data.blank?

    # Convert hash to array if needed
    items_array = if items_data.is_a?(Hash)
                    items_data.values
                  elsif items_data.is_a?(Array)
                    items_data
                  else
                    return
                  end

    return unless items_array.any?

    # Create a default menu section first
    menu_section = menu.menusections.create!(
      name: 'Demo Section',
      description: 'Demo menu items',
      status: 1, # active
      sequence: 1,
      archived: false,
    )

    items_array.each_with_index do |item_data, index|
      next unless item_data.is_a?(Hash)

      menu_item = menu_section.menuitems.create!(
        name: item_data['name'],
        description: item_data['description'],
        price: item_data['price'].to_f,
        calories: 750, # 750 calories
        preptime: 10, # 10 minutes prep time
        sequence: index + 1,
        archived: false,
        status: 1, # active
      )

      # Link allergens to menu items
      restaurant = menu.restaurant
      allergen1 = restaurant.allergyns.find_by(name: 'Allergen 1')
      allergen2 = restaurant.allergyns.find_by(name: 'Allergen 2')

      if allergen1
        MenuitemAllergynMapping.create!(menuitem: menu_item, allergyn: allergen1)
      end

      if allergen2
        MenuitemAllergynMapping.create!(menuitem: menu_item, allergyn: allergen2)
      end

      # Link sizes to the first menu item only
      if index.zero?
        small_size = restaurant.sizes.find_by(name: 'Small')
        medium_size = restaurant.sizes.find_by(name: 'Medium')
        large_size = restaurant.sizes.find_by(name: 'Large')

        base_price = menu_item.price

        if small_size
          MenuitemSizeMapping.create!(
            menuitem: menu_item,
            size: small_size,
            price: base_price * 0.8, # 20% less for small
          )
        end

        if medium_size
          MenuitemSizeMapping.create!(
            menuitem: menu_item,
            size: medium_size,
            price: base_price, # same price for medium
          )
        end

        if large_size
          MenuitemSizeMapping.create!(
            menuitem: menu_item,
            size: large_size,
            price: base_price * 1.3, # 30% more for large
          )
        end
      end

      # Create inventory entry for each menu item
      menu_item.create_inventory!(
        startinginventory: 10,
        currentinventory: 10,
        resethour: 9, # 9:00am
        status: :active,
        archived: false,
        sequence: index + 1,
      )
    end
  end

  def create_menu_availabilities(menu)
    restaurant = menu.restaurant

    # Create menu availabilities matching restaurant opening times
    restaurant.restaurantavailabilities.each do |restaurant_availability|
      menu.menuavailabilities.create!(
        dayofweek: restaurant_availability.dayofweek,
        starthour: restaurant_availability.starthour,
        startmin: restaurant_availability.startmin,
        endhour: restaurant_availability.endhour,
        endmin: restaurant_availability.endmin,
        status: :active,
        archived: false,
        sequence: restaurant_availability.sequence,
      )
    end
  end

  def create_owner_employee(restaurant, user)
    # Create employee record for the restaurant owner as manager
    restaurant.employees.create!(
      user: user,
      name: user.name,
      email: user.email,
      eid: "OWNER#{restaurant.id}",
      role: 'manager',
      status: 'active',
      archived: false,
      sequence: 1,
    )
  end

  def create_default_restaurant_settings(restaurant)
    # Create default table settings if none exist
    unless restaurant.tablesettings.exists?
      restaurant.tablesettings.create!(
        name: 'Table 1',
        description: 'Default table',
        capacity: 4,
        tabletype: :indoor, # indoor table type
        status: :free, # free status
        archived: false,
        sequence: 1,
      )
    end

    # Create default tax if none exist
    unless restaurant.taxes.exists?
      restaurant.taxes.create!(
        name: 'Default Tax',
        taxtype: :local, # local tax type
        taxpercentage: 10.0, # 10% tax
        archived: false,
        status: 1, # active
        sequence: 1,
      )
    end

    # Create default tip if none exist
    unless restaurant.tips.exists?
      restaurant.tips.create!(
        percentage: 10.0, # 10% tip
        archived: false,
        status: :active, # active status
        sequence: 1,
      )
    end

    # Create default restaurant locales if none exist
    unless restaurant.restaurantlocales.exists?
      # Create English locale as default
      restaurant.restaurantlocales.create!(
        locale: 'EN',
        status: :active,
        dfault: true, # Default locale
      )

      # Create Italian locale
      restaurant.restaurantlocales.create!(
        locale: 'IT',
        status: :active,
        dfault: false,
      )
    end

    # Create default restaurant opening times if none exist
    unless restaurant.restaurantavailabilities.exists?
      # Create opening times for all days except Monday (9:00am to 9:00pm)
      %i[sunday tuesday wednesday thursday friday saturday].each_with_index do |day, index|
        restaurant.restaurantavailabilities.create!(
          dayofweek: day,
          starthour: 9,   # 9:00am
          startmin: 0,
          endhour: 21,    # 9:00pm
          endmin: 0,
          status: :open,
          archived: false,
          sequence: index + 1,
        )
      end
    end

    # Create default allergens if none exist
    unless restaurant.allergyns.exists?
      restaurant.allergyns.create!(
        name: 'Allergen 1',
        description: 'Demo allergen 1',
        symbol: 'A1',
        status: :active,
        archived: false,
        sequence: 1,
      )

      restaurant.allergyns.create!(
        name: 'Allergen 2',
        description: 'Demo allergen 2',
        symbol: 'A2',
        status: :active,
        archived: false,
        sequence: 2,
      )
    end

    # Create default sizes if none exist
    return if restaurant.sizes.exists?

    restaurant.sizes.create!(
      size: :sm,
      name: 'Small',
      description: 'Small size',
      status: :active,
      archived: false,
      sequence: 1,
    )

    restaurant.sizes.create!(
      size: :md,
      name: 'Medium',
      description: 'Medium size',
      status: :active,
      archived: false,
      sequence: 2,
    )

    restaurant.sizes.create!(
      size: :lg,
      name: 'Large',
      description: 'Large size',
      status: :active,
      archived: false,
      sequence: 3,
    )
  end

  def detect_currency_from_location(location)
    return 'USD' if location.blank?

    # Simple currency detection based on common patterns
    case location.downcase
    when /uk|united kingdom|england|scotland|wales/
      'GBP'
    when /eu|europe|germany|france|italy|spain|netherlands/
      'EUR'
    when /canada/
      'CAD'
    when /australia/
      'AUD'
    else
      'USD'
    end
  end

  def detect_timezone_from_location(location)
    return 'UTC' if location.blank?

    # Simple timezone detection based on common patterns
    case location.downcase
    when /uk|united kingdom|england|scotland|wales/
      'Europe/London'
    when /germany|berlin/
      'Europe/Berlin'
    when /france|paris/
      'Europe/Paris'
    when /italy|rome/
      'Europe/Rome'
    when /spain|madrid/
      'Europe/Madrid'
    when /new york|ny/
      'America/New_York'
    when /los angeles|la|california/
      'America/Los_Angeles'
    when /chicago/
      'America/Chicago'
    when /australia|sydney/
      'Australia/Sydney'
    else
      'UTC'
    end
  end
end
