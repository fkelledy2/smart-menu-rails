require 'test_helper'

module Payments
  class SplitPlanCalculatorTest < ActiveSupport::TestCase
    def setup
      @restaurant = restaurants(:one)
      @ordr = ordrs(:one)
      @ordr.update!(status: 'billrequested', gross: 25.00, tip: 0)

      @active_participant = ordrparticipants(:two)
      @active_participant.update!(role: 'customer', sessionid: 'active-session-123')

      @inactive_participant = @ordr.ordrparticipants.create!(
        role: 'customer',
        sessionid: 'inactive-session',
        ordr: @ordr,
      )
      @inactive_participant.update_column(:sessionid, nil)
    end

    test 'rejects inactive participants without session' do
      calculator = Payments::SplitPlanCalculator.new(
        ordr: @ordr,
        split_method: :equal,
        participant_ids: [@inactive_participant.id],
      )

      result = calculator.call

      assert_not result.success?
      assert_match(/active order participants/i, result.errors.first)
    end

    test 'accepts active participants with session' do
      calculator = Payments::SplitPlanCalculator.new(
        ordr: @ordr,
        split_method: :equal,
        participant_ids: [@active_participant.id],
      )

      result = calculator.call

      assert result.success?
      assert_equal 1, result.shares.length
    end

    test 'rejects mix of active and inactive participants' do
      calculator = Payments::SplitPlanCalculator.new(
        ordr: @ordr,
        split_method: :equal,
        participant_ids: [@active_participant.id, @inactive_participant.id],
      )

      result = calculator.call

      assert_not result.success?
      assert_match(/active order participants/i, result.errors.first)
    end
  end
end
