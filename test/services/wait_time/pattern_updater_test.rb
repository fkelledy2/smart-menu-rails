require 'test_helper'

module WaitTime
  class PatternUpdaterTest < ActiveSupport::TestCase
    def setup
      @restaurant = restaurants(:one)
      @updater = PatternUpdater.new(@restaurant)
    end

    # ---------------------------------------------------------------------------
    # update! — no historical orders
    # ---------------------------------------------------------------------------

    test 'returns 0 when no closed orders exist' do
      # Close/delete all orders for this restaurant
      Ordr.where(restaurant: @restaurant).update_all(status: Ordr.statuses['opened'])
      result = @updater.update!
      assert_equal 0, result
    end

    # ---------------------------------------------------------------------------
    # update! — with sufficient closed orders
    # ---------------------------------------------------------------------------

    test 'creates dining pattern records from closed orders' do
      # Create several closed orders within the lookback window
      ts = @restaurant.tablesettings.first
      skip 'No tablesetting available' unless ts
      menu = menus(:one)

      # Pin all orders to the same day-of-week (every 7 days back) + hour bucket
      # so they all land in the same [party_size=2, day_of_week=X, hour_of_day=19] bucket
      anchor = Time.current.beginning_of_day + 19.hours # 7pm today
      5.times do |i|
        created = anchor - (i * 7).days # same day of week, successive weeks
        paid = created + 55.minutes
        Ordr.create!(
          restaurant: @restaurant,
          menu: menu,
          tablesetting: ts,
          status: Ordr.statuses['paid'],
          ordercapacity: 2,
          created_at: created,
          updated_at: paid,
          paidAt: paid,
        )
      end

      DiningPattern.where(restaurant: @restaurant).delete_all
      result = @updater.update!
      assert result >= 1, 'Should have created at least one pattern'

      pattern = DiningPattern.find_by(restaurant: @restaurant, party_size: 2)
      assert pattern.present?, 'Pattern for party_size=2 should exist'
      assert pattern.average_duration_minutes.positive?
      assert pattern.sample_count >= 1
    end

    test 'skips outlier orders with duration over 600 minutes' do
      ts = @restaurant.tablesettings.first
      skip 'No tablesetting available' unless ts

      created = 2.hours.ago
      paid_outlier = created + 700.minutes
      Ordr.create!(
        restaurant: @restaurant,
        menu: menus(:one),
        tablesetting: ts,
        status: Ordr.statuses['paid'],
        ordercapacity: 2,
        created_at: created,
        paidAt: paid_outlier,
      )

      DiningPattern.where(restaurant: @restaurant, party_size: 2).delete_all
      # Only this one outlier — below MIN_SAMPLE_SIZE (3) → returns 0
      result = @updater.update!
      assert_equal 0, result
    end

    test 'upserts existing patterns rather than duplicating' do
      ts = @restaurant.tablesettings.first
      skip 'No tablesetting available' unless ts
      menu = menus(:one)

      # Pin all orders to same day-of-week + hour bucket to exceed MIN_SAMPLE_SIZE
      anchor = Time.current.beginning_of_day + 20.hours # 8pm tonight
      5.times do |i|
        created = anchor - (i * 7).days
        paid = created + rand(40..90).minutes
        Ordr.create!(
          restaurant: @restaurant,
          menu: menu,
          tablesetting: ts,
          status: Ordr.statuses['paid'],
          ordercapacity: 2,
          created_at: created,
          paidAt: paid,
        )
      end

      DiningPattern.where(restaurant: @restaurant).delete_all

      @updater.update!
      count_after  = @updater.update!

      # Second run should upsert same records, not create duplicates
      assert_equal DiningPattern.where(restaurant: @restaurant).count, count_after
    end
  end
end
