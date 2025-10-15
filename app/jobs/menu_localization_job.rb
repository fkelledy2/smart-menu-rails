require 'sidekiq'
require 'deepl'

class MenuLocalizationJob
  include Sidekiq::Worker

  #   sidekiq_options queue: "limited"
  #
  #   extend Limiter::Mixin
  #   limit_method :expensive_api_call, rate: 4, interval: 60, balanced: true

  def perform(restaurant_id)
    expensive_api_call(restaurant_id)
  end

  private

  def expensive_api_call(restaurantlocaleid)
    restaurantlocale = Restaurantlocale.where(id: restaurantlocaleid).first
    restaurant = Restaurant.find(restaurantlocale.restaurant_id)
    return unless restaurant

    Menu.where(restaurant_id: restaurant.id).find_each do |menu|
      Menulocale.where(menu_id: menu.id, locale: restaurantlocale.locale).destroy_all
      menu_locale = Menulocale.new
      menu_locale.locale = restaurantlocale.locale
      menu_locale.status = restaurantlocale.status
      menu_locale.menu_id = menu.id
      if restaurantlocale.dfault == true
        menu_locale.name = menu.name
        menu_locale.description = menu.description
      else
        begin
          translation = DeeplApiService.translate(menu.name, to: restaurantlocale.locale, from: 'en')
          menu_locale.name = translation
        rescue StandardError
          menu_locale.name = menu.name
        end
        begin
          translation = DeeplApiService.translate(menu.description, to: restaurantlocale.locale, from: 'en')
          menu_locale.description = translation
        rescue StandardError
          menu_locale.description = menu.description
        end
      end
      menu_locale.save
      Menusection.where(menu_id: menu.id).find_each do |menusection|
        Menusectionlocale.where(menusection_id: menusection.id, locale: restaurantlocale.locale).destroy_all
        menusection_locale = Menusectionlocale.new
        menusection_locale.locale = restaurantlocale.locale
        menusection_locale.status = restaurantlocale.status
        menusection_locale.menusection_id = menusection.id
        if restaurantlocale.dfault == true
          menusection_locale.name = menusection.name
          menusection_locale.description = menusection.description
        else
          begin
            translation = DeeplApiService.translate(menusection.name, to: restaurantlocale.locale,
                                                                      from: 'en',)
            menusection_locale.name = translation
          rescue StandardError
            menusection_locale.name = menusection.name
          end
          begin
            translation = DeeplApiService.translate(menu.description, to: restaurantlocale.locale,
                                                                      from: 'en',)
            menusection_locale.description = translation
          rescue StandardError
            menusection_locale.description = menusection.description
          end
        end
        menusection_locale.save
        Menuitem.where(menusection_id: menusection.id).find_each do |menuitem|
          Menuitemlocale.where(menuitem_id: menuitem.id, locale: restaurantlocale.locale).destroy_all
          menu_item_locale = Menuitemlocale.new
          menu_item_locale.locale = restaurantlocale.locale
          menu_item_locale.status = restaurantlocale.status
          menu_item_locale.menuitem_id = menuitem.id
          if restaurantlocale.dfault == true
            menu_item_locale.name = menuitem.name
            menu_item_locale.description = menuitem.description
          else
            begin
              translation = DeeplApiService.translate(menuitem.name, to: restaurantlocale.locale,
                                                                     from: 'en',)
              menu_item_locale.name = translation
            rescue StandardError
              menu_item_locale.name = menuitem.name
            end
            begin
              translation = DeeplApiService.translate(menuitem.description, to: restaurantlocale.locale,
                                                                            from: 'en',)
              menu_item_locale.description = translation
            rescue StandardError
              menu_item_locale.description = menuitem.description
            end
          end
          menu_item_locale.save
        end
      end
    end
  end

  def ask_question(prompt)
    api_key = Rails.application.credentials.openai_api_key
    headers = { 'Authorization' => "Bearer #{api_key}", 'Content-Type' => 'application/json' }
    body = {
      messages: [{ role: 'user', content: prompt }],
      model: 'gpt-3.5-turbo',
    }.to_json
    HTTParty.post(
      'https://api.openai.com/v1/chat/completions',
      headers: headers,
      body: body,
    )
  end
end
