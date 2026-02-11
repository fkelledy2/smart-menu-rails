require 'test_helper'

class RestaurantClaimRequestTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
    @restaurant.update_columns(claim_status: 0) # unclaimed
    @user = users(:one)
  end

  test 'valid claim request saves' do
    cr = RestaurantClaimRequest.new(
      restaurant: @restaurant,
      claimant_email: 'owner@example.com',
      claimant_name: 'Jane Doe',
      verification_method: :email_domain,
      status: :started,
    )
    assert cr.valid?, cr.errors.full_messages.join(', ')
    assert cr.save
  end

  test 'requires claimant_email' do
    cr = RestaurantClaimRequest.new(
      restaurant: @restaurant,
      verification_method: :email_domain,
      status: :started,
    )
    assert_not cr.valid?
    assert_includes cr.errors[:claimant_email], "can't be blank"
  end

  test 'validates email format' do
    cr = RestaurantClaimRequest.new(
      restaurant: @restaurant,
      claimant_email: 'not-an-email',
      verification_method: :email_domain,
      status: :started,
    )
    assert_not cr.valid?
    assert cr.errors[:claimant_email].any?
  end

  test 'enum statuses' do
    cr = RestaurantClaimRequest.new(restaurant: @restaurant, claimant_email: 'a@b.com', verification_method: :email_domain)
    cr.status = :started
    assert cr.started?

    cr.status = :approved
    assert cr.approved?

    cr.status = :rejected
    assert cr.rejected?
  end

  test 'enum verification_methods' do
    %i[email_domain dns_txt gmb manual_upload].each do |method|
      cr = RestaurantClaimRequest.new(
        restaurant: @restaurant,
        claimant_email: 'a@b.com',
        status: :started,
        verification_method: method,
      )
      assert cr.valid?, "Expected #{method} to be valid"
    end
  end

  test 'approve! transitions restaurant to soft_claimed' do
    cr = RestaurantClaimRequest.create!(
      restaurant: @restaurant,
      claimant_email: 'owner@example.com',
      verification_method: :email_domain,
      status: :started,
    )

    cr.approve!(reviewer: @user)

    assert cr.approved?
    assert cr.verified_at.present?
    assert_equal @user, cr.reviewed_by_user
    @restaurant.reload
    assert @restaurant.soft_claimed?
  end

  test 'reject! sets status and notes' do
    cr = RestaurantClaimRequest.create!(
      restaurant: @restaurant,
      claimant_email: 'owner@example.com',
      verification_method: :email_domain,
      status: :started,
    )

    cr.reject!(reviewer: @user, notes: 'Insufficient evidence')

    assert cr.rejected?
    assert_equal 'Insufficient evidence', cr.review_notes
    assert_equal @user, cr.reviewed_by_user
  end
end
