require 'test_helper'

class PaymentProfileTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
    @profile = PaymentProfile.new(
      restaurant: @restaurant,
      merchant_model: :restaurant_mor,
      primary_provider: :stripe,
    )
  end

  test 'valid profile saves successfully' do
    assert @profile.save
  end

  test 'requires merchant_model' do
    @profile.merchant_model = nil
    assert_not @profile.valid?
  end

  test 'requires primary_provider' do
    @profile.primary_provider = nil
    assert_not @profile.valid?
  end

  test 'accepts restaurant_mor merchant model' do
    @profile.merchant_model = :restaurant_mor
    assert @profile.valid?
    assert @profile.restaurant_mor?
  end

  test 'accepts smartmenu_mor merchant model' do
    @profile.merchant_model = :smartmenu_mor
    assert @profile.valid?
    assert @profile.smartmenu_mor?
  end

  test 'accepts stripe as primary provider' do
    @profile.primary_provider = :stripe
    assert @profile.valid?
    assert @profile.stripe?
  end

  test 'accepts square as primary provider' do
    @profile.primary_provider = :square
    assert @profile.valid?
    assert @profile.square?
  end

  test 'belongs to restaurant' do
    @profile.save!
    assert_equal @restaurant, @profile.restaurant
  end
end
