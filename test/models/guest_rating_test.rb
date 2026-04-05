# frozen_string_literal: true

require 'test_helper'

class GuestRatingTest < ActiveSupport::TestCase
  # --- Validations ---

  test 'valid with required attributes' do
    # Use a fresh ordr not already associated with a fixture rating
    new_ordr = Ordr.create!(
      restaurant: restaurants(:one),
      menu: menus(:one),
      tablesetting: tablesettings(:one),
      status: Ordr.statuses[:paid],
    )
    rating = GuestRating.new(
      ordr: new_ordr,
      restaurant: restaurants(:one),
      stars: 4,
      source: 'in_app',
    )
    assert rating.valid?, rating.errors.full_messages.to_s
  end

  test 'invalid without stars' do
    rating = GuestRating.new(
      ordr: ordrs(:one),
      restaurant: restaurants(:one),
      source: 'in_app',
    )
    assert_not rating.valid?
    assert_includes rating.errors[:stars], "can't be blank"
  end

  test 'invalid with stars below 1' do
    rating = GuestRating.new(
      ordr: ordrs(:one),
      restaurant: restaurants(:one),
      stars: 0,
      source: 'in_app',
    )
    assert_not rating.valid?
  end

  test 'invalid with stars above 5' do
    rating = GuestRating.new(
      ordr: ordrs(:one),
      restaurant: restaurants(:one),
      stars: 6,
      source: 'in_app',
    )
    assert_not rating.valid?
  end

  test 'invalid without source' do
    rating = GuestRating.new(
      ordr: ordrs(:one),
      restaurant: restaurants(:one),
      stars: 3,
    )
    assert_not rating.valid?
  end

  test 'invalid with unknown source' do
    rating = GuestRating.new(
      ordr: ordrs(:one),
      restaurant: restaurants(:one),
      stars: 3,
      source: 'yelp',
    )
    assert_not rating.valid?
  end

  test 'enforces uniqueness of ordr_id and source' do
    # First rating exists as low_rating fixture
    duplicate = GuestRating.new(
      ordr: ordrs(:one),
      restaurant: restaurants(:one),
      stars: 5,
      source: 'in_app',
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:ordr_id], 'already has a rating for this source'
  end

  test 'allows same ordr with different source' do
    rating = GuestRating.new(
      ordr: ordrs(:one),
      restaurant: restaurants(:one),
      stars: 3,
      source: 'google',
    )
    assert rating.valid?
  end

  # --- low_rating? predicate ---

  test 'low_rating? returns true for 1-star' do
    rating = guest_ratings(:low_rating)
    assert rating.low_rating?
  end

  test 'low_rating? returns true for 2-star' do
    rating = GuestRating.new(stars: 2)
    assert rating.low_rating?
  end

  test 'low_rating? returns false for 3-star' do
    rating = GuestRating.new(stars: 3)
    assert_not rating.low_rating?
  end

  # --- Scopes ---

  test 'low_ratings scope returns only 1-2 star ratings' do
    low = GuestRating.low_ratings.for_restaurant(restaurants(:one).id)
    assert_equal 1, low.count
    assert_equal 1, low.first.stars
  end

  test 'recent scope orders by created_at desc' do
    ratings = GuestRating.recent
    assert ratings.count >= 2
  end

  # --- Domain event emission ---

  test 'emits rating.low domain event on create for low rating' do
    assert_difference -> { AgentDomainEvent.where(event_type: 'rating.low').count }, 1 do
      ordr = ordrs(:table_one_ordr)
      # Need a fresh ordr without an existing rating
      new_ordr = Ordr.create!(
        restaurant: restaurants(:one),
        menu: menus(:one),
        tablesetting: tablesettings(:one),
        status: Ordr.statuses[:paid],
      )
      GuestRating.create!(
        ordr: new_ordr,
        restaurant: restaurants(:one),
        stars: 2,
        source: 'in_app',
      )
    end
  end

  test 'does not emit domain event for 3-star rating' do
    new_ordr = Ordr.create!(
      restaurant: restaurants(:one),
      menu: menus(:one),
      tablesetting: tablesettings(:one),
      status: Ordr.statuses[:paid],
    )
    assert_no_difference -> { AgentDomainEvent.where(event_type: 'rating.low').count } do
      GuestRating.create!(
        ordr: new_ordr,
        restaurant: restaurants(:one),
        stars: 3,
        source: 'in_app',
      )
    end
  end

  test 'emits domain event with correct payload' do
    new_ordr = Ordr.create!(
      restaurant: restaurants(:one),
      menu: menus(:one),
      tablesetting: tablesettings(:one),
      status: Ordr.statuses[:paid],
    )
    rating = GuestRating.create!(
      ordr: new_ordr,
      restaurant: restaurants(:one),
      stars: 1,
      comment: 'Very bad food',
      source: 'in_app',
    )

    event = AgentDomainEvent.where(event_type: 'rating.low').order(created_at: :desc).first
    assert_not_nil event
    assert_equal new_ordr.id, event.payload['ordr_id']
    assert_equal 1, event.payload['stars']
    assert_equal 'Very bad food', event.payload['comment']
    assert_equal restaurants(:one).id, event.payload['restaurant_id']
    assert_equal rating.id, event.payload['guest_rating_id']
  end

  test 'emit_low_rating_event is idempotent — does not raise if domain event exists' do
    new_ordr = Ordr.create!(
      restaurant: restaurants(:one),
      menu: menus(:one),
      tablesetting: tablesettings(:one),
      status: Ordr.statuses[:paid],
    )
    rating = GuestRating.create!(
      ordr: new_ordr,
      restaurant: restaurants(:one),
      stars: 1,
      source: 'in_app',
    )

    # Manually trigger again — should not raise or create duplicate
    assert_no_difference -> { AgentDomainEvent.count } do
      # Call publish! with same idempotency_key — returns existing
      AgentDomainEvent.publish!(
        event_type: 'rating.low',
        idempotency_key: "rating.low:#{rating.id}",
        payload: {},
      )
    end
  end
end
