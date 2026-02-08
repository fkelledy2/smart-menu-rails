require 'test_helper'

class AuthorizationMonitoringServiceTest < ActiveSupport::TestCase
  setup do
    @service = AuthorizationMonitoringService.instance
    @user = users(:one)
    @restaurant = restaurants(:one)
    @restaurant.update(user: @user)
  end

  test 'tracks successful authorization check' do
    assert_nothing_raised do
      AuthorizationMonitoringService.track_authorization_check(
        @user,
        @restaurant,
        :show,
        true,
        { controller: 'restaurants', request_ip: '127.0.0.1' },
      )
    end
  end

  test 'tracks authorization check with nil user' do
    assert_nothing_raised do
      AuthorizationMonitoringService.track_authorization_check(
        nil,
        @restaurant,
        :show,
        false,
        {},
      )
    end
  end

  test 'tracks authorization failure' do
    exception = Pundit::NotAuthorizedError.new('Not authorized')

    assert_nothing_raised do
      AuthorizationMonitoringService.track_authorization_failure(
        @user,
        @restaurant,
        :destroy,
        exception,
        { controller: 'restaurants', request_ip: '127.0.0.1' },
      )
    end
  end

  test 'determines user role as owner' do
    role = @service.send(:determine_user_role, @user, @restaurant)
    assert_equal 'owner', role
  end

  test 'determines user role as anonymous for nil user' do
    role = @service.send(:determine_user_role, nil, @restaurant)
    assert_equal 'anonymous', role
  end

  test 'determines user role as customer for non-owner' do
    other_user = users(:two)
    role = @service.send(:determine_user_role, other_user, @restaurant)
    assert_equal 'customer', role
  end

  test 'extracts restaurant from restaurant resource' do
    restaurant = @service.send(:extract_restaurant, @restaurant)
    assert_equal @restaurant, restaurant
  end

  test 'extracts restaurant from menu resource' do
    menu = menus(:one)
    menu.update(restaurant: @restaurant)
    restaurant = @service.send(:extract_restaurant, menu)
    assert_equal @restaurant, restaurant
  end

  test 'returns nil for resource without restaurant' do
    user = users(:one)
    restaurant = @service.send(:extract_restaurant, user)
    assert_nil restaurant
  end

  test 'generates authorization report' do
    report = AuthorizationMonitoringService.generate_authorization_report(
      1.week.ago,
      Time.current,
    )

    assert_not_nil report
    assert_includes report.keys, :period
    assert_includes report.keys, :summary
    assert_includes report.keys, :by_user_role
    assert_includes report.keys, :by_resource_type
    assert_includes report.keys, :by_action
    assert_includes report.keys, :failures
    assert_includes report.keys, :recommendations
  end

  test 'report summary contains expected keys' do
    report = AuthorizationMonitoringService.generate_authorization_report
    summary = report[:summary]

    assert_includes summary.keys, :total_checks
    assert_includes summary.keys, :total_failures
    assert_includes summary.keys, :failure_rate
    assert_includes summary.keys, :unique_users
  end

  test 'report includes role breakdown' do
    report = AuthorizationMonitoringService.generate_authorization_report
    role_breakdown = report[:by_user_role]

    assert_includes role_breakdown.keys, 'owner'
    assert_includes role_breakdown.keys, 'customer'
    assert_includes role_breakdown.keys, 'anonymous'
  end

  test 'report includes resource breakdown' do
    report = AuthorizationMonitoringService.generate_authorization_report
    resource_breakdown = report[:by_resource_type]

    assert_includes resource_breakdown.keys, 'Restaurant'
    assert_includes resource_breakdown.keys, 'Menu'
    assert_includes resource_breakdown.keys, 'Ordr'
  end

  test 'report includes action breakdown' do
    report = AuthorizationMonitoringService.generate_authorization_report
    action_breakdown = report[:by_action]

    assert_includes action_breakdown.keys, 'show'
    assert_includes action_breakdown.keys, 'update'
    assert_includes action_breakdown.keys, 'destroy'
  end

  test 'report includes recommendations' do
    report = AuthorizationMonitoringService.generate_authorization_report
    recommendations = report[:recommendations]

    assert_kind_of Array, recommendations
    assert recommendations.any?
  end

  test 'handles authorization check without context' do
    assert_nothing_raised do
      AuthorizationMonitoringService.track_authorization_check(
        @user,
        @restaurant,
        :show,
        true,
      )
    end
  end

  test 'handles authorization failure without context' do
    exception = StandardError.new('Test error')

    assert_nothing_raised do
      AuthorizationMonitoringService.track_authorization_failure(
        @user,
        @restaurant,
        :show,
        exception,
      )
    end
  end
end
