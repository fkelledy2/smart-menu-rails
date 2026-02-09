require 'test_helper'

class Madmin::ImpersonatesControllerTest < ActiveSupport::TestCase
  setup do
    @super_admin = users(:super_admin)
    @target = users(:one)

    @controller = Madmin::ImpersonatesController.new
    @request = ActionDispatch::TestRequest.create
    @response = ActionDispatch::TestResponse.new
    @controller.request = @request
    @controller.response = @response
  end

  test 'super admin can start impersonation and creates audit' do
    fake_session = {}
    fake_params = ActionController::Parameters.new(id: @target.id.to_s)

    @request.host = 'www.example.com'
    @request.remote_addr = '127.0.0.1'
    @request.user_agent = 'test'

    @controller.stub(:current_user, @super_admin) do
      @controller.stub(:session, fake_session) do
        @controller.stub(:params, fake_params) do
          @controller.stub(:impersonate_user, true) do
            @controller.stub(:redirect_to, true) do
              @controller.stub(:root_path, '/') do
                assert_difference('ImpersonationAudit.count', 1) do
                  @controller.impersonate
                end
              end
            end
          end
        end
      end
    end

    audit = ImpersonationAudit.order(:id).last
    assert_equal @super_admin.id, audit.admin_user_id
    assert_equal @target.id, audit.impersonated_user_id
    assert_nil audit.ended_at

    assert_equal audit.id, fake_session[:impersonation_audit_id]
    assert fake_session[:impersonation_expires_at].present?
  end
end
