# frozen_string_literal: true

require 'test_helper'

class DiscoveredRestaurantWebMenuScrapeJobTest < ActiveSupport::TestCase
  # DiscoveredRestaurantWebMenuScrapeJob orchestrates web menu discovery, scraping,
  # GPT processing, and OcrMenuImport creation.
  # Tests stub all external services to avoid HTTP calls.

  def setup
    @restaurant = restaurants(:one)
    @dr = DiscoveredRestaurant.create!(
      name: 'Scrape Test Restaurant',
      google_place_id: "manual_test_#{SecureRandom.hex(4)}",
      city_name: 'Dublin',
      website_url: 'https://example-menu.com',
      status: 'pending',
    )
  end

  def teardown
    @dr&.destroy! if @dr&.persisted?
  end

  def stub_no_op_finder(html_pages: [], pdfs: [])
    finder = Object.new
    finder.define_singleton_method(:find_menus) { |**_opts| { html_menu_pages: html_pages, pdfs: pdfs } }
    finder
  end

  test 'perform is a no-op when discovered restaurant does not exist' do
    assert_nothing_raised do
      DiscoveredRestaurantWebMenuScrapeJob.new.perform(discovered_restaurant_id: -999)
    end
  end

  test 'perform sets failed status when website_url is blank' do
    @dr.update!(website_url: '')

    DiscoveredRestaurantWebMenuScrapeJob.new.perform(discovered_restaurant_id: @dr.id)

    @dr.reload
    status = @dr.metadata&.dig('web_menu_scrape', 'status')
    assert_equal 'failed', status
  end

  test 'perform sets completed status when no html pages and no pdfs found' do
    finder = stub_no_op_finder(html_pages: [], pdfs: [])
    robots = Object.new
    robots.define_singleton_method(:allowed?) { |*_args| true }

    MenuDiscovery::RobotsTxtChecker.stub(:new, robots) do
      MenuDiscovery::WebsiteMenuFinder.stub(:new, ->(**_opts) { finder }) do
        DiscoveredRestaurantWebMenuScrapeJob.new.perform(discovered_restaurant_id: @dr.id)
      end
    end

    @dr.reload
    status = @dr.metadata&.dig('web_menu_scrape', 'status')
    assert_equal 'completed', status
  end

  test 'perform completes when html pages found but scraper returns blank text' do
    finder = stub_no_op_finder(html_pages: ['https://example.com/menu'], pdfs: [])
    scraper = Object.new
    scraper.define_singleton_method(:scrape) { |_pages| { menu_text: '', pages_scraped: 0, source_urls: [] } }
    robots = Object.new
    robots.define_singleton_method(:allowed?) { |*_args| true }

    MenuDiscovery::RobotsTxtChecker.stub(:new, robots) do
      MenuDiscovery::WebsiteMenuFinder.stub(:new, ->(**_opts) { finder }) do
        MenuDiscovery::WebMenuScraper.stub(:new, ->(**_opts) { scraper }) do
          DiscoveredRestaurantWebMenuScrapeJob.new.perform(discovered_restaurant_id: @dr.id)
        end
      end
    end

    @dr.reload
    status = @dr.metadata&.dig('web_menu_scrape', 'status')
    assert_equal 'completed', status
  end

  test 'perform completes with no import when no linked restaurant' do
    @dr.update_column(:restaurant_id, nil) if @dr.respond_to?(:restaurant_id)

    finder = stub_no_op_finder(html_pages: ['https://example.com/menu'], pdfs: [])
    scraper = Object.new
    scraper.define_singleton_method(:scrape) do |_pages|
      { menu_text: 'Burger 12', pages_scraped: 1, source_urls: ['https://example.com/menu'] }
    end
    robots = Object.new
    robots.define_singleton_method(:allowed?) { |*_args| true }

    MenuDiscovery::RobotsTxtChecker.stub(:new, robots) do
      MenuDiscovery::WebsiteMenuFinder.stub(:new, ->(**_opts) { finder }) do
        MenuDiscovery::WebMenuScraper.stub(:new, ->(**_opts) { scraper }) do
          @dr.stub(:restaurant, nil) do
            DiscoveredRestaurantWebMenuScrapeJob.new.perform(discovered_restaurant_id: @dr.id)
          end
        end
      end
    end

    @dr.reload
    status = @dr.metadata&.dig('web_menu_scrape', 'status')
    assert_equal 'completed', status
  end
end
