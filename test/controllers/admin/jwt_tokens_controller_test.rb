# frozen_string_literal: true

require 'test_helper'

class Admin::JwtTokensControllerTest < ActionDispatch::IntegrationTest
  setup do
    @mellow_admin = users(:super_admin)  # admin@mellow.menu, admin: true
    @plain_admin  = users(:admin)        # admin@gmail.com, admin: true
    @regular_user = users(:one)
    @restaurant   = restaurants(:one)
    @active_token = admin_jwt_tokens(:active_token)
    @revoked_token = admin_jwt_tokens(:revoked_token)
  end

  # ---------------------------------------------------------------------------
  # Access control
  # ---------------------------------------------------------------------------

  test 'unauthenticated user cannot access index' do
    get admin_jwt_tokens_path
    assert_response :redirect
  end

  test 'non-mellow admin is redirected from index' do
    sign_in @plain_admin
    get admin_jwt_tokens_path
    assert_redirected_to root_path
  end

  test 'regular user is redirected from index' do
    sign_in @regular_user
    get admin_jwt_tokens_path
    assert_redirected_to root_path
  end

  # ---------------------------------------------------------------------------
  # Index
  # ---------------------------------------------------------------------------

  test 'mellow admin can access index' do
    sign_in @mellow_admin
    get admin_jwt_tokens_path
    assert_response :ok
  end

  test 'index lists tokens' do
    sign_in @mellow_admin
    get admin_jwt_tokens_path
    assert_select 'table'
  end

  # ---------------------------------------------------------------------------
  # Show
  # ---------------------------------------------------------------------------

  test 'mellow admin can view token' do
    sign_in @mellow_admin
    get admin_jwt_token_path(@active_token)
    assert_response :ok
  end

  test 'non-mellow admin cannot view token' do
    sign_in @plain_admin
    get admin_jwt_token_path(@active_token)
    assert_redirected_to root_path
  end

  # ---------------------------------------------------------------------------
  # New / Create
  # ---------------------------------------------------------------------------

  test 'mellow admin can load new form' do
    sign_in @mellow_admin
    get new_admin_jwt_token_path
    assert_response :ok
  end

  test 'create generates a new token and redirects to show' do
    sign_in @mellow_admin

    assert_difference 'AdminJwtToken.count', 1 do
      post admin_jwt_tokens_path, params: {
        admin_jwt_token: {
          restaurant_id: @restaurant.id,
          name: 'Controller Test Token',
          scopes: ['menu:read'],
          expiry_preset: '30_days',
          rate_limit_per_minute: 60,
          rate_limit_per_hour: 1000,
        },
      }
    end

    assert_redirected_to admin_jwt_token_path(AdminJwtToken.order(:created_at).last)
  end

  test 'create stores raw JWT in flash and it is accessible on the show page' do
    sign_in @mellow_admin

    post admin_jwt_tokens_path, params: {
      admin_jwt_token: {
        restaurant_id: @restaurant.id,
        name: 'Flash JWT Test',
        scopes: ['menu:read'],
        expiry_preset: '30_days',
        rate_limit_per_minute: 60,
        rate_limit_per_hour: 1000,
      },
    }

    # After POST, the response is a redirect — flash is set
    assert_redirected_to admin_jwt_token_path(AdminJwtToken.order(:created_at).last)

    # Follow redirect to show page — flash is rendered in the response
    follow_redirect!
    assert_response :ok
    # The show template renders raw_jwt from flash — look for the JWT copy notice
    assert_match 'Copy your token now', response.body
  end

  test 'create with invalid params re-renders new form' do
    sign_in @mellow_admin

    assert_no_difference 'AdminJwtToken.count' do
      post admin_jwt_tokens_path, params: {
        admin_jwt_token: {
          restaurant_id: @restaurant.id,
          name: '', # blank name — invalid
          scopes: ['menu:read'],
          expiry_preset: '30_days',
          rate_limit_per_minute: 60,
          rate_limit_per_hour: 1000,
        },
      }
    end

    assert_response :unprocessable_content
  end

  # ---------------------------------------------------------------------------
  # Revoke
  # ---------------------------------------------------------------------------

  test 'mellow admin can revoke an active token' do
    sign_in @mellow_admin

    assert_nil @active_token.revoked_at

    post revoke_admin_jwt_token_path(@active_token)

    @active_token.reload
    assert @active_token.revoked?
    assert_redirected_to admin_jwt_token_path(@active_token)
  end

  test 'non-mellow admin cannot revoke' do
    sign_in @plain_admin
    post revoke_admin_jwt_token_path(@active_token)
    assert_redirected_to root_path
    assert_nil @active_token.reload.revoked_at
  end

  # ---------------------------------------------------------------------------
  # Send email
  # ---------------------------------------------------------------------------

  test 'send_email enqueues mailer and redirects' do
    sign_in @mellow_admin

    assert_enqueued_emails 1 do
      post send_email_admin_jwt_token_path(@active_token), params: {
        raw_jwt: 'fake.raw.jwt',
        recipient_email: 'owner@example.com',
      }
    end

    assert_redirected_to admin_jwt_token_path(@active_token)
  end

  test 'send_email redirects with alert when raw_jwt is absent' do
    sign_in @mellow_admin

    post send_email_admin_jwt_token_path(@active_token), params: {
      recipient_email: 'owner@example.com',
    }

    assert_redirected_to admin_jwt_token_path(@active_token)
    assert flash[:alert].present?
  end

  # ---------------------------------------------------------------------------
  # Download link
  # ---------------------------------------------------------------------------

  test 'download_link returns a text file when raw_jwt present' do
    sign_in @mellow_admin

    post download_link_admin_jwt_token_path(@active_token), params: {
      raw_jwt: 'fake.raw.jwt',
    }

    assert_response :ok
    assert_equal 'text/plain; charset=utf-8', response.content_type
  end

  test 'download_link redirects with alert when raw_jwt absent' do
    sign_in @mellow_admin

    post download_link_admin_jwt_token_path(@active_token)

    assert_redirected_to admin_jwt_token_path(@active_token)
    assert flash[:alert].present?
  end
end
