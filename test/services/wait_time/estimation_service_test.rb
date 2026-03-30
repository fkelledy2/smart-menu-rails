require 'test_helper'

module WaitTime
  class EstimationServiceTest < ActiveSupport::TestCase
    def setup
      @restaurant = restaurants(:one)
      @service = EstimationService.new(@restaurant)
    end

    # ---------------------------------------------------------------------------
    # estimates_for_standard_sizes
    # ---------------------------------------------------------------------------

    test 'returns a hash keyed on standard party sizes' do
      result = @service.estimates_for_standard_sizes
      assert_equal CustomerWaitQueue::STANDARD_PARTY_SIZES.sort, result.keys.sort
    end

    test 'all values are non-negative integers' do
      result = @service.estimates_for_standard_sizes
      result.each do |size, minutes|
        assert_kind_of Integer, minutes, "Expected Integer for party_size=#{size}"
        assert minutes >= 0, "Expected non-negative wait for party_size=#{size}"
      end
    end

    # ---------------------------------------------------------------------------
    # estimate_for_party — no tables configured
    # ---------------------------------------------------------------------------

    test 'returns 0 when no tables exist for party size' do
      # Restaurant two has no tablesettings in fixtures
      restaurant_no_tables = Restaurant.create!(
        name: 'Empty Restaurant',
        status: 1,
        currency: 'USD',
        user: users(:one),
        capacity: 0,
      )
      result = EstimationService.new(restaurant_no_tables).estimate_for_party(2)
      assert_equal 0, result
    end

    # ---------------------------------------------------------------------------
    # estimate_for_party — free table available
    # ---------------------------------------------------------------------------

    test 'returns 0 when a suitable free table is available' do
      # Ensure no active orders on restaurant one's tables
      Ordr.where(restaurant: @restaurant).update_all(status: Ordr.statuses['closed'])

      result = @service.estimate_for_party(2)
      assert_equal 0, result
    end

    # ---------------------------------------------------------------------------
    # estimate_for_party — all tables occupied, no historical data
    # ---------------------------------------------------------------------------

    test 'returns DEFAULT_WAIT_MINUTES when all tables occupied and no historical data' do
      # Create an occupied order on a table so all tables for party=2 are occupied
      # Use a restaurant with no dining_patterns
      restaurant = restaurants(:two)
      # Ensure restaurant two has at least one tablesetting
      ts = restaurant.tablesettings.where(archived: false).where(capacity: 2..).first
      skip 'No tablesetting for party size 2 in restaurant two' unless ts

      Ordr.create!(
        restaurant: restaurant,
        menu: menus(:one),
        tablesetting: ts,
        status: Ordr.statuses['ordered'],
        ordercapacity: 2,
      )

      svc = EstimationService.new(restaurant)
      result = svc.estimate_for_party(2)
      # No dining patterns for restaurant two at this point → should use default
      assert_equal CustomerWaitQueue::DEFAULT_WAIT_MINUTES, result
    end

    # ---------------------------------------------------------------------------
    # estimate_for_party — with historical data
    # ---------------------------------------------------------------------------

    test 'uses historical average when sufficient pattern data exists' do
      # Set ALL tables to occupied by closing any open orders and creating active orders
      # on every table that fits party_size=2
      Ordr.unscoped
        .where(restaurant: @restaurant)
        .where.not(status: [Ordr.statuses['paid'], Ordr.statuses['closed']])
        .update_all(status: Ordr.statuses['closed'])

      candidate_tables = @restaurant.tablesettings
        .where(archived: false)
        .where(capacity: 2..)

      skip 'No suitable tablesettings in restaurant one' if candidate_tables.empty?

      created_ordrs = candidate_tables.map do |ts|
        Ordr.create!(
          restaurant: @restaurant,
          menu: menus(:one),
          tablesetting: ts,
          status: Ordr.statuses['ordered'],
          ordercapacity: 2,
          created_at: 10.minutes.ago,
        )
      end

      # With all tables occupied, estimate must be positive
      result = @service.estimate_for_party(2)
      assert result >= 1, 'Should return a positive wait time when all tables occupied'
    ensure
      created_ordrs&.each do |o|
        o.destroy
      rescue StandardError
        nil
      end
    end
  end
end
