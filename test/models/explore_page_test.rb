# frozen_string_literal: true

require 'test_helper'

class ExplorePageTest < ActiveSupport::TestCase
  setup do
    @page = ExplorePage.new(
      country_slug: 'ireland',
      country_name: 'Ireland',
      city_slug: 'dublin',
      city_name: 'Dublin',
      restaurant_count: 5,
      published: true,
    )
  end

  test 'valid explore page' do
    assert @page.valid?
  end

  test 'requires country_slug' do
    @page.country_slug = nil
    assert_not @page.valid?
    assert_includes @page.errors[:country_slug], "can't be blank"
  end

  test 'requires city_slug' do
    @page.city_slug = nil
    assert_not @page.valid?
    assert_includes @page.errors[:city_slug], "can't be blank"
  end

  test 'requires country_name' do
    @page.country_name = nil
    assert_not @page.valid?
  end

  test 'requires city_name' do
    @page.city_name = nil
    assert_not @page.valid?
  end

  test 'path returns city-level path when no category' do
    assert_equal '/explore/ireland/dublin', @page.path
  end

  test 'path returns category path when category present' do
    @page.category_slug = 'italian'
    assert_equal '/explore/ireland/dublin/italian', @page.path
  end

  test 'published scope returns only published pages' do
    @page.save!
    unpublished = ExplorePage.create!(
      country_slug: 'italy', country_name: 'Italy',
      city_slug: 'rome', city_name: 'Rome',
      published: false,
    )

    results = ExplorePage.published
    assert_includes results, @page
    assert_not_includes results, unpublished
  end

  test 'city_level scope returns pages without category' do
    @page.save!
    with_cat = ExplorePage.create!(
      country_slug: 'ireland', country_name: 'Ireland',
      city_slug: 'dublin', city_name: 'Dublin',
      category_slug: 'italian', category_name: 'Italian',
      published: true,
    )

    results = ExplorePage.city_level
    assert_includes results, @page
    assert_not_includes results, with_cat
  end

  test 'category_slug uniqueness is scoped to country and city' do
    @page.category_slug = 'italian'
    @page.save!

    duplicate = ExplorePage.new(
      country_slug: 'ireland', country_name: 'Ireland',
      city_slug: 'dublin', city_name: 'Dublin',
      category_slug: 'italian',
    )
    assert_not duplicate.valid?
  end

  test 'allows same category_slug in different cities' do
    @page.category_slug = 'italian'
    @page.save!

    different_city = ExplorePage.new(
      country_slug: 'ireland', country_name: 'Ireland',
      city_slug: 'cork', city_name: 'Cork',
      category_slug: 'italian', category_name: 'Italian',
      published: true,
    )
    assert different_city.valid?
  end
end
