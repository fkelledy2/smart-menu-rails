# frozen_string_literal: true

require 'test_helper'

class RestaurantCurrencyInferenceTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test 'infers EUR for IE' do
    r = Restaurant.create!(user: @user, name: 'Test', country: 'IE', status: 0)
    assert_equal 'EUR', r.currency
  end

  test 'infers USD for US' do
    r = Restaurant.create!(user: @user, name: 'Test', country: 'US', status: 0)
    assert_equal 'USD', r.currency
  end

  test 'infers GBP for GB' do
    r = Restaurant.create!(user: @user, name: 'Test', country: 'GB', status: 0)
    assert_equal 'GBP', r.currency
  end

  test 'does not override existing currency' do
    r = Restaurant.create!(user: @user, name: 'Test', country: 'US', currency: 'EUR', status: 0)
    assert_equal 'EUR', r.currency
  end

  test 'updates currency when country changes' do
    r = Restaurant.create!(user: @user, name: 'Test', country: 'US', status: 0)
    assert_equal 'USD', r.currency
    r.update!(country: 'GB', currency: nil)
    assert_equal 'GBP', r.currency
  end
end
