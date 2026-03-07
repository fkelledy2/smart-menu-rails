require 'test_helper'

class Admin::LocalGuidesControllerTest < ActiveSupport::TestCase
  setup do
    @admin_user = users(:admin)
    @super_admin_user = users(:super_admin)
    @guide = LocalGuide.create!(
      title: 'Best Brunch in Dublin',
      city: 'Dublin',
      country: 'Ireland',
      category: 'Brunch',
      content: '<p>Brunch guide content</p>',
      status: :draft,
    )

    @controller = Admin::LocalGuidesController.new
    @request = ActionDispatch::TestRequest.create
    @response = ActionDispatch::TestResponse.new
    @controller.request = @request
    @controller.response = @response
  end

  test 'approve publishes guide and records approver' do
    fake_params = ActionController::Parameters.new(id: @guide.id.to_s)

    @controller.stub(:current_user, @super_admin_user) do
      @controller.stub(:params, fake_params) do
        @controller.instance_variable_set(:@local_guide, @guide)

        @controller.stub(:authenticate_user!, true) do
          @controller.stub(:authorize, true) do
            @controller.stub(:admin_local_guide_path, "/admin/local_guides/#{@guide.id}") do
              @controller.stub(:redirect_to, true) do
                @controller.approve
              end
            end
          end
        end
      end
    end

    @guide.reload
    assert @guide.published?
    assert_not_nil @guide.published_at
    assert_equal @super_admin_user.id, @guide.approved_by_user_id
  end

  test 'archive marks guide archived' do
    @guide.update!(status: :published, published_at: Time.current)
    fake_params = ActionController::Parameters.new(id: @guide.id.to_s)

    @controller.stub(:current_user, @admin_user) do
      @controller.stub(:params, fake_params) do
        @controller.instance_variable_set(:@local_guide, @guide)

        @controller.stub(:authenticate_user!, true) do
          @controller.stub(:authorize, true) do
            @controller.stub(:admin_local_guide_path, "/admin/local_guides/#{@guide.id}") do
              @controller.stub(:redirect_to, true) do
                @controller.archive
              end
            end
          end
        end
      end
    end

    @guide.reload
    assert @guide.archived?
  end
end
