require 'test_helper'

class TestimonialsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = users(:one)
    @other_user = users(:two)
    @admin = users(:admin)
    @testimonial = testimonials(:one)
  end

  # ---------------------------------------------------------------------------
  # index — admin only
  # ---------------------------------------------------------------------------

  test 'GET /testimonials redirects unauthenticated users' do
    get testimonials_path
    assert_redirected_to new_user_session_path
  end

  test 'GET /testimonials redirects non-admin with flash alert' do
    sign_in @owner
    get testimonials_path
    assert_response :redirect
    follow_redirect!
    assert_not_nil flash[:alert]
  end

  test 'GET /testimonials succeeds for admin' do
    sign_in @admin
    get testimonials_path
    assert_response :success
  end

  # ---------------------------------------------------------------------------
  # show
  # ---------------------------------------------------------------------------

  test 'GET /testimonials/:id succeeds for owner' do
    sign_in @owner
    get testimonial_path(@testimonial)
    assert_response :success
  end

  # ---------------------------------------------------------------------------
  # new / create
  # ---------------------------------------------------------------------------

  test 'POST /testimonials creates testimonial for authenticated user' do
    sign_in @owner
    assert_difference('Testimonial.count') do
      post testimonials_path, params: {
        testimonial: {
          testimonial: 'A new review',
          user_id: @owner.id,
          restaurant_id: restaurants(:one).id,
        },
      }
    end
    assert_redirected_to testimonial_path(Testimonial.last)
  end

  # ---------------------------------------------------------------------------
  # update — authorization guard
  # ---------------------------------------------------------------------------

  test 'PATCH /testimonials/:id succeeds for owner' do
    sign_in @owner
    patch testimonial_path(@testimonial), params: {
      testimonial: { testimonial: 'Updated text' },
    }
    assert_redirected_to testimonial_path(@testimonial)
    assert_equal 'Updated text', @testimonial.reload.testimonial
  end

  test 'PATCH /testimonials/:id is blocked for non-owner non-admin' do
    sign_in @other_user
    patch testimonial_path(@testimonial), params: {
      testimonial: { testimonial: 'Hijacked' },
    }
    assert_response :redirect
    assert_not_equal 'Hijacked', @testimonial.reload.testimonial
  end

  test 'PATCH /testimonials/:id succeeds for admin' do
    sign_in @admin
    patch testimonial_path(@testimonial), params: {
      testimonial: { testimonial: 'Admin edit' },
    }
    assert_redirected_to testimonial_path(@testimonial)
    assert_equal 'Admin edit', @testimonial.reload.testimonial
  end

  # ---------------------------------------------------------------------------
  # destroy — authorization guard
  # ---------------------------------------------------------------------------

  test 'DELETE /testimonials/:id is blocked for non-owner' do
    sign_in @other_user
    delete testimonial_path(@testimonial)
    assert_response :redirect
    assert Testimonial.exists?(@testimonial.id)
  end

  test 'DELETE /testimonials/:id succeeds for owner' do
    sign_in @owner
    assert_difference('Testimonial.count', -1) do
      delete testimonial_path(@testimonial)
    end
    assert_redirected_to testimonials_path
  end

  test 'DELETE /testimonials/:id succeeds for admin' do
    sign_in @admin
    assert_difference('Testimonial.count', -1) do
      delete testimonial_path(@testimonial)
    end
    assert_redirected_to testimonials_path
  end
end
