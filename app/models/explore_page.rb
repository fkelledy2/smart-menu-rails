# frozen_string_literal: true

class ExplorePage < ApplicationRecord
  scope :published, -> { where(published: true) }
  scope :city_level, -> { where(category_slug: nil) }
  scope :with_restaurants, -> { where('restaurant_count > 0') }

  validates :country_slug, :country_name, :city_slug, :city_name, presence: true
  validates :category_slug, uniqueness: { scope: %i[country_slug city_slug], allow_nil: true }

  def path
    if category_slug.present?
      "/explore/#{country_slug}/#{city_slug}/#{category_slug}"
    else
      "/explore/#{country_slug}/#{city_slug}"
    end
  end

  # Returns restaurants for this explore page
  def restaurants
    scope = Restaurant.where(preview_enabled: true)
      .where('LOWER(city) = ?', city_name.downcase)
      .where('LOWER(country) = ?', country_name.downcase)

    if category_slug.present?
      scope = scope.where('? = ANY(establishment_types)', category_name)
    end

    scope.order(
      Arel.sql('CASE WHEN claim_status IN (2,3) THEN 0 ELSE 1 END ASC'),
      :name,
    )
  end
end
