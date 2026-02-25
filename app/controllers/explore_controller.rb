# frozen_string_literal: true

class ExploreController < ApplicationController
  # No authentication required — public pages
  skip_before_action :authenticate_user!, raise: false
  skip_before_action :set_current_employee, raise: false
  skip_before_action :set_permissions, raise: false
  skip_before_action :redirect_to_onboarding_if_needed, raise: false

  layout 'application'

  def index
    @countries = ExplorePage.published.select(:country_slug, :country_name)
      .distinct.order(:country_name)
    @page_title = 'Explore Restaurant Menus | mellow.menu'
    @page_description = 'Discover restaurant menus by city. Prices, allergens, and descriptions.'
    @canonical_url = 'https://www.mellow.menu/explore'
    @og_title = @page_title
    @og_description = @page_description
    @og_url = @canonical_url
  end

  def country
    @country = params[:country]
    @cities = ExplorePage.published
      .where(country_slug: @country)
      .city_level
      .order(:city_name)
    render_404 and return if @cities.empty?

    country_name = @cities.first.country_name
    @page_title = "Restaurants in #{country_name} | mellow.menu"
    @page_description = "Explore restaurant menus across #{country_name}."
    @canonical_url = "https://www.mellow.menu/explore/#{@country}"
    @og_title = @page_title
    @og_description = @page_description
    @og_url = @canonical_url
  end

  def city
    @page = ExplorePage.published.find_by!(
      country_slug: params[:country],
      city_slug: params[:city],
      category_slug: nil,
    )
    @restaurants = @page.restaurants.limit(100)
    @categories = ExplorePage.published
      .where(country_slug: params[:country], city_slug: params[:city])
      .where.not(category_slug: nil)
      .order(:category_name)
    set_explore_meta_tags
    set_explore_schema_org
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def show
    @page = ExplorePage.published.find_by!(
      country_slug: params[:country],
      city_slug: params[:city],
      category_slug: params[:category],
    )
    @restaurants = @page.restaurants.limit(100)
    set_explore_meta_tags
    set_explore_schema_org
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  private

  def set_explore_meta_tags
    @page_title = @page.meta_title.presence ||
                  "#{@page.category_name || 'All'} Restaurants in #{@page.city_name}, #{@page.country_name} | mellow.menu"
    @page_description = @page.meta_description.presence ||
                        "Discover #{@page.category_name&.downcase || ''} restaurants in #{@page.city_name}. View menus, prices, and allergen info."
    @canonical_url = "https://www.mellow.menu#{@page.path}"
    @og_title = @page_title
    @og_description = @page_description
    @og_url = @canonical_url
  end

  def set_explore_schema_org
    items = @restaurants.first(50).map.with_index do |r, i|
      {
        '@type' => 'ListItem',
        'position' => i + 1,
        'item' => {
          '@type' => 'Restaurant',
          'name' => r.name,
          'address' => { '@type' => 'PostalAddress', 'addressLocality' => r.city }.compact,
          'servesCuisine' => r.establishment_types,
        }.compact,
      }
    end

    @schema_org_json_ld = JSON.generate({
      '@context' => 'https://schema.org',
      '@type' => 'ItemList',
      'name' => @page_title,
      'numberOfItems' => @restaurants.size,
      'itemListElement' => items,
    })
  end

  def render_404
    render file: Rails.public_path.join('404.html'), status: :not_found, layout: false
  end
end
