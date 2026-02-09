require 'test_helper'

class Madmin::ImpersonatesControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  tests Madmin::ImpersonatesController

  setup do
    @routes = Rails.application.routes
    @super_admin = users(:super_admin)
    @target = users(:one)

    @request.env['devise.mapping'] = Devise.mappings[:user]

    Madmin::ApplicationController.skip_before_action(:authenticate_user!, raise: false)
    Madmin::ApplicationController.skip_before_action(:ensure_admin!, raise: false)

    Madmin::ImpersonatesController.skip_before_action(:authenticate_user!, raise: false)
    Madmin::ImpersonatesController.skip_before_action(:ensure_admin!, raise: false)
    Madmin::ImpersonatesController.skip_before_action(:require_super_admin!, raise: false)

    Madmin::ImpersonatesController.skip_before_action(:set_current_employee, raise: false)
    Madmin::ImpersonatesController.skip_before_action(:set_permissions, raise: false)
    Madmin::ImpersonatesController.skip_before_action(:redirect_to_onboarding_if_needed, raise: false)
    Madmin::ImpersonatesController.skip_before_action(:enforce_impersonation_expiry, raise: false)
    Madmin::ImpersonatesController.skip_before_action(:block_high_risk_actions_when_impersonating, raise: false)
    Madmin::ImpersonatesController.skip_around_action(:switch_locale, raise: false)

    @orig_current_user = Madmin::ImpersonatesController.instance_method(:current_user) if Madmin::ImpersonatesController.method_defined?(:current_user)
    @orig_find_user_for_impersonation = Madmin::ImpersonatesController.instance_method(:find_user_for_impersonation)
    @orig_impersonate_user = Madmin::ImpersonatesController.instance_method(:impersonate_user)
  end

  teardown do
    if @orig_current_user
      Madmin::ImpersonatesController.define_method(:current_user, @orig_current_user)
    end

    Madmin::ImpersonatesController.define_method(:find_user_for_impersonation, @orig_find_user_for_impersonation)
    Madmin::ImpersonatesController.define_method(:impersonate_user, @orig_impersonate_user)
  end

  test 'super admin can start impersonation by email and creates audit' do
    u = @super_admin
    target = @target

    Madmin::ImpersonatesController.define_method(:current_user) { u }
    Madmin::ImpersonatesController.define_method(:find_user_for_impersonation) { |_query| target }
    Madmin::ImpersonatesController.define_method(:impersonate_user) { |_user| true }

    fake_session = {}
    fake_request = Struct.new(:remote_ip, :user_agent).new('127.0.0.1', 'test')
    fake_params = ActionController::Parameters.new(query: @target.email, reason: 'debug')

    @controller.stub(:session, fake_session) do
      @controller.stub(:request, fake_request) do
        @controller.stub(:params, fake_params) do
          @controller.stub(:root_path, '/') do
            @controller.stub(:redirect_to, true) do
              assert_difference('ImpersonationAudit.count', 1) do
                @controller.start
              end
            end
          end
        end
      end
    end

    audit = ImpersonationAudit.order(:id).last
    assert_equal @super_admin.id, audit.admin_user_id
    assert_equal @target.id, audit.impersonated_user_id
    assert_equal 'debug', audit.reason
    assert_nil audit.ended_at

    assert_equal audit.id, fake_session[:impersonation_audit_id]
    assert fake_session[:impersonation_expires_at].present?
  end

  test 'expired impersonation session is stopped and audit is finalized' do
    audit = ImpersonationAudit.create!(
      admin_user: @super_admin,
      impersonated_user: @target,
      started_at: 31.minutes.ago,
      expires_at: 1.minute.ago,
      ip_address: '127.0.0.1',
      user_agent: 'test',
    )

    session[:impersonation_audit_id] = audit.id
    session[:impersonation_expires_at] = 1.minute.ago.iso8601

    @controller.stub(:impersonating_user?, true) do
      @controller.stub(:stop_impersonating_user, true) do
        @controller.stub(:redirect_to, true) do
          @controller.enforce_impersonation_expiry
        end
      end
    end

    audit.reload
    assert_equal 'expired', audit.ended_reason
    assert audit.ended_at.present?
  end
end
