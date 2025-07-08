# frozen_string_literal: true

module Localisable
  extend ActiveSupport::Concern

  class_methods do
    # Configure the concern with the locale model and foreign key
    def localisable(locale_model:, locale_foreign_key:, parent_chain: nil)
      define_method :localised_name do |locale|
        locale_record = locale_model.constantize.find_by(locale_foreign_key => id, locale: locale)
        restaurant_locale = parent_chain ? parent_chain.call(self).restaurant.restaurantlocales.find_by(locale: locale) : nil
        if restaurant_locale&.dfault
          name
        else
          locale_record&.name || name
        end
      end

      define_method :localised_description do |locale|
        locale_record = locale_model.constantize.find_by(locale_foreign_key => id, locale: locale)
        restaurant_locale = parent_chain ? parent_chain.call(self).restaurant.restaurantlocales.find_by(locale: locale) : nil
        if restaurant_locale&.dfault
          description
        else
          locale_record&.description || description
        end
      end
    end
  end
end
