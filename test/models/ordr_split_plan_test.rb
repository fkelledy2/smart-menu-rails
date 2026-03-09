require 'test_helper'

class OrdrSplitPlanTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
    @ordr = ordrs(:one)
    @ordr.update!(status: 'billrequested', gross: 25.00, tip: 0)
    
    @plan = @ordr.create_ordr_split_plan!(
      split_method: 'equal',
      plan_status: 'validated',
      created_by_user: users(:one),
      participant_count: 2
    )
  end

  test 'update_status_from_settlement marks plan completed when all shares settled' do
    @plan.ordr_split_payments.create!(
      ordr: @ordr,
      ordrparticipant: ordrparticipants(:two),
      amount_cents: 1250,
      base_amount_cents: 1250,
      tax_amount_cents: 0,
      tip_amount_cents: 0,
      service_charge_amount_cents: 0,
      currency: @restaurant.currency || 'USD',
      provider: 'stripe',
      split_method: 'equal',
      status: 'succeeded'
    )
    
    @plan.ordr_split_payments.create!(
      ordr: @ordr,
      ordrparticipant: ordrparticipants(:three),
      amount_cents: 1250,
      base_amount_cents: 1250,
      tax_amount_cents: 0,
      tip_amount_cents: 0,
      service_charge_amount_cents: 0,
      currency: @restaurant.currency || 'USD',
      provider: 'stripe',
      split_method: 'equal',
      status: 'succeeded'
    )
    
    @plan.update_status_from_settlement!
    
    assert_equal 'completed', @plan.plan_status
  end

  test 'update_status_from_settlement marks plan failed when any share failed' do
    @plan.ordr_split_payments.create!(
      ordr: @ordr,
      ordrparticipant: ordrparticipants(:two),
      amount_cents: 1250,
      base_amount_cents: 1250,
      tax_amount_cents: 0,
      tip_amount_cents: 0,
      service_charge_amount_cents: 0,
      currency: @restaurant.currency || 'USD',
      provider: 'stripe',
      split_method: 'equal',
      status: 'failed'
    )
    
    @plan.update_status_from_settlement!
    
    assert_equal 'failed', @plan.plan_status
  end

  test 'update_status_from_settlement freezes plan when share is in flight' do
    @plan.ordr_split_payments.create!(
      ordr: @ordr,
      ordrparticipant: ordrparticipants(:two),
      amount_cents: 1250,
      base_amount_cents: 1250,
      tax_amount_cents: 0,
      tip_amount_cents: 0,
      service_charge_amount_cents: 0,
      currency: @restaurant.currency || 'USD',
      provider: 'stripe',
      split_method: 'equal',
      status: 'pending'
    )
    
    @plan.update_status_from_settlement!
    
    assert_equal 'frozen', @plan.plan_status
    assert @plan.split_frozen?
  end

  test 'update_status_from_settlement does not change completed plan' do
    @plan.update!(plan_status: 'completed')
    
    @plan.update_status_from_settlement!
    
    assert_equal 'completed', @plan.plan_status
  end

  test 'update_status_from_settlement does not change canceled plan' do
    @plan.update!(plan_status: 'canceled')
    
    @plan.update_status_from_settlement!
    
    assert_equal 'canceled', @plan.plan_status
  end
end
