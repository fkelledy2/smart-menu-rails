# frozen_string_literal: true

require 'test_helper'

class Payments::SplitPlanUpsertServiceTest < ActiveSupport::TestCase
  # SplitPlanUpsertService delegates calculation to SplitPlanCalculator and then
  # persists the plan + split payment rows inside a transaction.
  #
  # Pre-conditions:
  #   - Order must be in billrequested state (enforced by SplitPlanCalculator)
  #   - Participants must have a non-blank sessionid (active participants)

  def setup
    @restaurant = restaurants(:one)
    @ordr = ordrs(:one)
    @actor = users(:one)

    # Bill-requested state is required for the calculator to accept the order.
    @ordr.update_columns(status: Ordr.statuses[:billrequested], gross: 30_00.to_f / 100)

    # Two active customer participants with sessions
    @p1 = @ordr.ordrparticipants.create!(
      role: :customer,
      sessionid: "split-test-sess-#{SecureRandom.hex(4)}",
    )
    @p2 = @ordr.ordrparticipants.create!(
      role: :customer,
      sessionid: "split-test-sess-#{SecureRandom.hex(4)}",
    )
  end

  # ---------------------------------------------------------------------------
  # Equal split — create
  # ---------------------------------------------------------------------------

  test 'creates a new OrdrSplitPlan for equal split' do
    svc = build_service(split_method: :equal, participant_ids: [@p1.id, @p2.id])

    assert_difference 'OrdrSplitPlan.count', 1 do
      result = svc.call
      assert result.success?, result.errors.inspect
    end
  end

  test 'equal split creates one OdrSplitPayment per participant' do
    svc = build_service(split_method: :equal, participant_ids: [@p1.id, @p2.id])

    result = svc.call
    assert result.success?, result.errors.inspect
    assert_equal 2, result.plan.ordr_split_payments.count
  end

  test 'equal split sets plan_status to validated' do
    svc = build_service(split_method: :equal, participant_ids: [@p1.id, @p2.id])

    result = svc.call
    assert result.success?
    assert result.plan.plan_status_validated?
  end

  test 'equal split sets participant_count on the plan' do
    svc = build_service(split_method: :equal, participant_ids: [@p1.id, @p2.id])

    result = svc.call
    assert result.success?
    assert_equal 2, result.plan.participant_count
  end

  test 'equal split split payments have status requires_payment' do
    svc = build_service(split_method: :equal, participant_ids: [@p1.id, @p2.id])

    result = svc.call
    assert result.success?
    result.plan.ordr_split_payments.each do |payment|
      assert_equal 'requires_payment', payment.status
    end
  end

  test 'equal split uses restaurant currency, defaults to USD' do
    @restaurant.update!(currency: nil)
    svc = build_service(split_method: :equal, participant_ids: [@p1.id, @p2.id])

    result = svc.call
    assert result.success?
    result.plan.ordr_split_payments.each do |payment|
      assert_equal 'USD', payment.currency
    end
  end

  test 'equal split uses restaurant currency when set' do
    # Update via the ordr's own restaurant association so the service picks it up
    @ordr.restaurant.update!(currency: 'GBP')
    @ordr.reload

    svc = build_service(split_method: :equal, participant_ids: [@p1.id, @p2.id])

    result = svc.call
    assert result.success?, result.errors.inspect
    result.plan.ordr_split_payments.each do |payment|
      assert_equal 'GBP', payment.currency
    end
  ensure
    @ordr.restaurant.update!(currency: 'USD')
  end

  # ---------------------------------------------------------------------------
  # Percentage split
  # ---------------------------------------------------------------------------

  test 'percentage split creates plan when basis points sum to 10000' do
    svc = build_service(
      split_method: :percentage,
      participant_ids: [@p1.id, @p2.id],
      percentage_basis_points: { @p1.id => 6000, @p2.id => 4000 },
    )

    result = svc.call
    assert result.success?, result.errors.inspect
    assert_equal 2, result.plan.ordr_split_payments.count
  end

  test 'percentage split fails when basis points do not sum to 10000' do
    svc = build_service(
      split_method: :percentage,
      participant_ids: [@p1.id, @p2.id],
      percentage_basis_points: { @p1.id => 5000, @p2.id => 4000 }, # only 90%
    )

    result = svc.call
    assert_not result.success?
    assert_match(/100%/i, result.errors.first)
  end

  # ---------------------------------------------------------------------------
  # Update — replace existing plan
  # ---------------------------------------------------------------------------

  test 'updates an existing plan (replace split payments)' do
    # First call — creates plan
    first_svc = build_service(split_method: :equal, participant_ids: [@p1.id, @p2.id])
    first_result = first_svc.call
    assert first_result.success?

    initial_payment_ids = first_result.plan.ordr_split_payments.pluck(:id)

    # Second call — replaces split payments
    second_svc = build_service(split_method: :equal, participant_ids: [@p1.id])
    second_result = second_svc.call
    assert second_result.success?

    updated_payment_ids = second_result.plan.ordr_split_payments.pluck(:id)

    # Payment rows were replaced
    assert_equal 1, updated_payment_ids.length
    assert_empty initial_payment_ids & updated_payment_ids
  end

  # ---------------------------------------------------------------------------
  # Frozen plan rejection
  # ---------------------------------------------------------------------------

  test 'rejects update when plan has a share in flight' do
    # Create plan
    svc = build_service(split_method: :equal, participant_ids: [@p1.id, @p2.id])
    result = svc.call
    assert result.success?

    plan = result.plan

    # Simulate in-flight share: set one payment to pending (in_flight status)
    plan.ordr_split_payments.first.update!(status: :pending)

    # Attempt to update the frozen plan
    update_svc = build_service(split_method: :equal, participant_ids: [@p1.id])
    update_result = update_svc.call

    assert_not update_result.success?
    assert_match(/frozen/i, update_result.errors.first)
  end

  # ---------------------------------------------------------------------------
  # Calculator failure propagation
  # ---------------------------------------------------------------------------

  test 'returns errors when order is not billrequested' do
    @ordr.update_columns(status: Ordr.statuses[:opened])

    svc = build_service(split_method: :equal, participant_ids: [@p1.id])
    result = svc.call

    assert_not result.success?
    assert result.errors.any?
  end

  test 'returns errors when no participant IDs are provided' do
    svc = build_service(split_method: :equal, participant_ids: [])
    result = svc.call

    assert_not result.success?
    assert result.errors.any?
  end

  # ---------------------------------------------------------------------------
  # Item-based split
  # ---------------------------------------------------------------------------

  test 'item_based split creates item assignments for each share' do
    # All payable items on the order must be assigned AND their total must equal
    # the order subtotal (gross - tax - tip - service).
    # Set ordr totals to match the fixture item prices: 15.99 + 5.99 + 2.99 = 24.97
    @ordr.update_columns(gross: 24.97, nett: 24.97, tax: 0, tip: 0, service: 0)

    item_ids = @ordr.ordritems.where.not(status: Ordritem.statuses['removed']).pluck(:id)

    svc = build_service(
      split_method: :item_based,
      participant_ids: [@p1.id],
      item_assignments: { @p1.id => item_ids },
    )

    result = svc.call
    assert result.success?, result.errors.inspect
    assert_equal item_ids.length, result.plan.ordr_split_item_assignments.count
  end

  private

  def build_service(split_method:, participant_ids:, custom_amounts_cents: {}, percentage_basis_points: {}, item_assignments: {})
    Payments::SplitPlanUpsertService.new(
      ordr: @ordr,
      actor: @actor,
      split_method: split_method,
      participant_ids: participant_ids,
      custom_amounts_cents: custom_amounts_cents,
      percentage_basis_points: percentage_basis_points,
      item_assignments: item_assignments,
    )
  end
end
