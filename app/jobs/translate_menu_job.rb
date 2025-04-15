require 'sidekiq'
require "deepl"

class TranslateMenuJob
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
    if( restaurant )
        Menu.where(restaurant_id: restaurant.id).each do |menu|
            Menusection.where( menu_id: menu.id).each do |menusection|
                Menuitem.where( menusection_id: menusection.id).each do |menuitem|
                    Menuitemlocale.where(menuitem_id: menuitem.id, locale: restaurantlocale.locale).destroy_all
                    menu_item_locale = Menuitemlocale.new()
                    menu_item_locale.locale = restaurantlocale.locale
                    menu_item_locale.status = restaurantlocale.status
                    menu_item_locale.menuitem_id = menuitem.id
                    if restaurantlocale.dfault == true
                        menu_item_locale.name = menuitem.name
                        menu_item_locale.description = menuitem.description
                    else
                        begin
                            translation = DeeplApiService.translate(menuitem.name, to: restaurantlocale.locale, from: 'en')
                            menu_item_locale.name = translation
                            puts 'Localising:'
                            puts menuitem.name
                            puts menu_item_locale.name
                        rescue ActiveRecord::CatchAll
                            menu_item_locale.name = menuitem.name
                        end
                        begin
                            translation = DeeplApiService.translate(menuitem.description, to: restaurantlocale.locale, from: 'en')
                            menu_item_locale.description = translation
                            puts menuitem.description
                            puts menu_item_locale.description
                        rescue ActiveRecord::CatchAll
                            menu_item_locale.description = menuitem.description
                        end
                    end
                    menu_item_locale.save
                end
            end
        end
    end
  end

  def ask_question(prompt)
        api_key = Rails.application.credentials.openai_api_key
        headers = { 'Authorization' => "Bearer #{api_key}", 'Content-Type' => 'application/json' }
        body = {
            messages: [{ role: 'user', content: prompt }],
            model: 'gpt-3.5-turbo'
        }.to_json
        HTTParty.post(
          'https://api.openai.com/v1/chat/completions',
          headers: headers,
          body: body
        )
  end
end
