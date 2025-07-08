# frozen_string_literal: true

module Localisable
  extend ActiveSupport::Concern

  class_methods do
    # Configure the concern with the locale model and foreign key
    def localisable(locale_model:, locale_foreign_key:, parent_chain: nil)
      define_method :localised_name do |locale|
        @localised_name_cache ||= {}
        return @localised_name_cache[locale] if @localised_name_cache.key?(locale)

        # Use in-memory association if loaded, else fallback to DB
        locale_assoc = send(locale_model.underscore.pluralize)
        locale_record = if locale_assoc.loaded?
          locale_assoc.detect { |l| l.locale == locale }
        else
          locale_assoc.find_by(locale: locale)
        end

        restaurant_locale = nil
        if parent_chain
          restaurantlocales_assoc = parent_chain.call(self).restaurant.restaurantlocales
          restaurant_locale = if restaurantlocales_assoc.loaded?
            restaurantlocales_assoc.detect { |l| l.locale == locale }
          else
            restaurantlocales_assoc.find_by(locale: locale)
          end
        end

        result = if restaurant_locale&.dfault
          name
        else
          locale_record&.name || name
        end
        @localised_name_cache[locale] = result
      end

      define_method :localised_description do |locale|
        @localised_description_cache ||= {}
        return @localised_description_cache[locale] if @localised_description_cache.key?(locale)

        # Use in-memory association if loaded, else fallback to DB
        locale_assoc = send(locale_model.underscore.pluralize)
        locale_record = if locale_assoc.loaded?
          locale_assoc.detect { |l| l.locale == locale }
        else
          locale_assoc.find_by(locale: locale)
        end

        restaurant_locale = nil
        if parent_chain
          restaurantlocales_assoc = parent_chain.call(self).restaurant.restaurantlocales
          restaurant_locale = if restaurantlocales_assoc.loaded?
            restaurantlocales_assoc.detect { |l| l.locale == locale }
          else
            restaurantlocales_assoc.find_by(locale: locale)
          end
        end

        result = if restaurant_locale&.dfault
          description
        else
          locale_record&.description || description
        end
        @localised_description_cache[locale] = result
      end
    end
  end
end
