# frozen_string_literal: true

module Api
  module V2
    class RestaurantsController < BaseController
      def index
        scope = Restaurant.where(preview_enabled: true)

        scope = scope.where("LOWER(city) = ?", params[:city].downcase) if params[:city].present?
        scope = scope.where("LOWER(country) = ?", params[:country].downcase) if params[:country].present?
        if params[:category].present?
          scope = scope.where("? = ANY(establishment_types)", params[:category])
        end

        scope = scope.order(:name)
        result = paginate(scope)

        render json: {
          data: result[:data].map { |r| restaurant_summary(r) },
          meta: result[:meta],
          attribution: "Data by mellow.menu",
          generated_at: Time.current.iso8601,
        }
      end

      def show
        restaurant = Restaurant.where(preview_enabled: true).find(params[:id])

        render json: {
          data: restaurant_detail(restaurant),
          attribution: "Data by mellow.menu",
          generated_at: Time.current.iso8601,
        }
      end

      def menu
        restaurant = Restaurant.where(preview_enabled: true).find(params[:id])
        menu = restaurant.menus.first
        return render json: { error: "No menu found" }, status: :not_found unless menu

        menusections = menu.menusections
                           .where(archived: false)
                           .includes(menuitems: :allergyns)
                           .order(:sequence)

        serializer = SchemaOrgSerializer.new(
          restaurant: restaurant,
          menu: menu,
          menusections: menusections,
          smartmenu: Smartmenu.find_by(restaurant_id: restaurant.id, tablesetting_id: nil) ||
                     OpenStruct.new(slug: "restaurant-#{restaurant.id}"),
        )

        render json: {
          data: JSON.parse(serializer.to_json_ld),
          attribution: "Data by mellow.menu",
          generated_at: Time.current.iso8601,
        }
      end

      private

      def restaurant_summary(r)
        {
          "@type" => "Restaurant",
          "id" => r.id,
          "name" => r.name,
          "city" => r.city,
          "country" => r.country,
          "servesCuisine" => r.establishment_types,
        }.compact
      end

      def restaurant_detail(r)
        {
          "@context" => "https://schema.org",
          "@type" => "Restaurant",
          "id" => r.id,
          "name" => r.name,
          "description" => r.description,
          "address" => address_hash(r),
          "geo" => geo_hash(r),
          "servesCuisine" => r.establishment_types,
        }.compact
      end

      def address_hash(r)
        return nil if r.address1.blank?
        {
          "@type" => "PostalAddress",
          "streetAddress" => [r.address1, r.address2].compact_blank.join(", "),
          "addressLocality" => r.city,
          "addressRegion" => r.state,
          "postalCode" => r.postcode,
          "addressCountry" => r.country,
        }.compact
      end

      def geo_hash(r)
        return nil if r.latitude.blank? || r.longitude.blank?
        {
          "@type" => "GeoCoordinates",
          "latitude" => r.latitude,
          "longitude" => r.longitude,
        }
      end
    end
  end
end
