# frozen_string_literal: true

# Discovers valid country/city/category combinations from restaurant data
# and creates/updates ExplorePage records. Runs nightly after sitemap generation.
class ExplorePageGeneratorJob < ApplicationJob
  queue_as :low

  MIN_RESTAURANTS_FOR_PAGE = 1

  def perform
    @category_counts = Hash.new(0)
    @category_names = {}

    generate_city_pages
    generate_category_pages
    unpublish_empty_pages
    Rails.logger.info("[ExplorePageGeneratorJob] Refresh complete")
  end

  private

  def generate_city_pages
    Restaurant.where(preview_enabled: true)
              .where.not(city: [nil, ''])
              .where.not(country: [nil, ''])
              .group(:city, :country)
              .having("COUNT(*) >= ?", MIN_RESTAURANTS_FOR_PAGE)
              .count
              .each do |(city, country), count|
      page = ExplorePage.find_or_initialize_by(
        country_slug: country.parameterize,
        city_slug: city.parameterize,
        category_slug: nil,
      )
      page.assign_attributes(
        country_name: country,
        city_name: city,
        restaurant_count: count,
        published: true,
        last_refreshed_at: Time.current,
      )
      page.save!
    end
  end

  def generate_category_pages
    Restaurant.where(preview_enabled: true)
              .where.not(city: [nil, ''])
              .where.not(establishment_types: [])
              .find_each do |r|
      r.establishment_types.each do |etype|
        key = [r.city.parameterize, r.country.parameterize, etype.parameterize]
        @category_counts[key] += 1
        @category_names[key] = [r.city, r.country, etype]
      end
    end

    @category_counts.each do |key, count|
      next if count < MIN_RESTAURANTS_FOR_PAGE
      city, country, category = @category_names[key]

      page = ExplorePage.find_or_initialize_by(
        country_slug: country.parameterize,
        city_slug: city.parameterize,
        category_slug: category.parameterize,
      )
      page.assign_attributes(
        country_name: country,
        city_name: city,
        category_name: category,
        restaurant_count: count,
        published: true,
        last_refreshed_at: Time.current,
      )
      page.save!
    end
  end

  def unpublish_empty_pages
    ExplorePage.where(published: true)
               .where("last_refreshed_at < ? OR last_refreshed_at IS NULL", 1.hour.ago)
               .update_all(published: false)
  end
end
