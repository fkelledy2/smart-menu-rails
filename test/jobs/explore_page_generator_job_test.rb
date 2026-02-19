# frozen_string_literal: true

require 'test_helper'

class ExplorePageGeneratorJobTest < ActiveSupport::TestCase
  test 'job is enqueued on the low queue' do
    assert_equal 'low', ExplorePageGeneratorJob.new.queue_name
  end

  test 'unpublish_empty_pages marks stale pages as unpublished' do
    stale = ExplorePage.create!(
      country_slug: 'ireland', country_name: 'Ireland',
      city_slug: 'dublin', city_name: 'Dublin',
      published: true,
      last_refreshed_at: 2.hours.ago,
    )

    ExplorePageGeneratorJob.new.perform

    stale.reload
    assert_not stale.published, 'Expected stale page to be unpublished'
  end
end
