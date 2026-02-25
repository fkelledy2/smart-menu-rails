# frozen_string_literal: true

module Api
  module V2
    class ExploreController < BaseController
      def index
        scope = ExplorePage.published.order(:country_name, :city_name)
        result = paginate(scope)

        render json: {
          data: result[:data].map { |p| explore_summary(p) },
          meta: result[:meta],
          attribution: 'Data by mellow.menu',
          generated_at: Time.current.iso8601,
        }
      end

      def show
        page = ExplorePage.published.find(params[:path])

        restaurants = page.restaurants.limit(50)

        render json: {
          data: {
            path: page.path,
            country: page.country_name,
            city: page.city_name,
            category: page.category_name,
            restaurant_count: page.restaurant_count,
            restaurants: restaurants.map { |r| restaurant_summary(r) },
          },
          attribution: 'Data by mellow.menu',
          generated_at: Time.current.iso8601,
        }
      end

      private

      def explore_summary(page)
        {
          id: page.id,
          path: page.path,
          country: page.country_name,
          city: page.city_name,
          category: page.category_name,
          restaurant_count: page.restaurant_count,
        }
      end

      def restaurant_summary(r)
        {
          id: r.id,
          name: r.name,
          city: r.city,
          country: r.country,
          servesCuisine: r.establishment_types,
        }.compact
      end
    end
  end
end
