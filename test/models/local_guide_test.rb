# frozen_string_literal: true

require 'test_helper'

class LocalGuideTest < ActiveSupport::TestCase
  setup do
    @guide = LocalGuide.new(
      title: 'Best Italian Restaurants in Dublin',
      city: 'Dublin',
      country: 'Ireland',
      category: 'Italian',
      content: '<p>Discover the finest Italian dining in Dublin.</p>',
    )
  end

  test 'valid guide' do
    assert @guide.valid?
  end

  test 'requires title' do
    @guide.title = nil
    assert_not @guide.valid?
    assert_includes @guide.errors[:title], "can't be blank"
  end

  test 'requires city' do
    @guide.city = nil
    assert_not @guide.valid?
  end

  test 'requires country' do
    @guide.country = nil
    assert_not @guide.valid?
  end

  test 'requires content' do
    @guide.content = nil
    assert_not @guide.valid?
  end

  test 'generates slug on create' do
    @guide.save!
    assert @guide.slug.present?, 'Expected slug to be generated'
    assert_match(/dublin-italian/, @guide.slug)
  end

  test 'slug is unique' do
    @guide.save!
    duplicate = LocalGuide.new(
      title: 'Another Italian Guide',
      slug: @guide.slug,
      city: 'Dublin',
      country: 'Ireland',
      content: '<p>More content</p>',
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:slug], 'has already been taken'
  end

  test 'status enum works' do
    @guide.save!
    assert @guide.draft?
    assert_not @guide.published?

    @guide.update!(status: :published, published_at: Time.current)
    assert @guide.published?

    @guide.update!(status: :archived)
    assert @guide.archived?
  end

  test 'published scope returns only published guides' do
    @guide.save!
    published_guide = LocalGuide.create!(
      title: 'Published Guide',
      city: 'Dublin',
      country: 'Ireland',
      content: '<p>Published</p>',
      status: :published,
      published_at: Time.current,
    )

    results = LocalGuide.published
    assert_includes results, published_guide
    assert_not_includes results, @guide
  end

  test 'faq_data defaults to empty array' do
    @guide.save!
    assert_equal [], @guide.faq_data
  end

  test 'referenced_restaurants defaults to empty array' do
    @guide.save!
    assert_equal [], @guide.referenced_restaurants
  end
end
