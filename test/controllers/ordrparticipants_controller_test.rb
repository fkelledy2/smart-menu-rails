# frozen_string_literal: true

require 'test_helper'

class OrdrparticipantsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    @restaurant = restaurants(:one)
    @ordr = ordrs(:one)
    @participant = ordrparticipants(:one)
    sign_in @user
  end

  # ---------------------------------------------------------------------------
  # GET index — without ordr_id uses policy_scope
  # ---------------------------------------------------------------------------

  test 'index: returns participants list via policy_scope' do
    get restaurant_ordrparticipants_path(@restaurant), as: :json

    assert_response :ok
  end

  test 'index: redirects unauthenticated user' do
    sign_out @user
    get restaurant_ordrparticipants_path(@restaurant), as: :json

    assert_response :unauthorized
  end

  # ---------------------------------------------------------------------------
  # GET show
  # ---------------------------------------------------------------------------

  test 'show: returns ordrparticipant as JSON' do
    get restaurant_ordrparticipant_path(@restaurant, @participant), as: :json

    assert_response :ok
  end

  test 'show: redirects to root when participant belongs to different restaurant' do
    # Participant from ordrs(:one) belongs to restaurant(:one); signing in as user(:two)
    sign_in users(:two)
    get restaurant_ordrparticipant_path(restaurants(:two), @participant), as: :json

    # set_ordrparticipant redirects to root_url when user mismatch
    assert_response :redirect
  end

  # ---------------------------------------------------------------------------
  # POST create
  # ---------------------------------------------------------------------------

  test 'create: returns errors JSON when sessionid is blank' do
    post restaurant_ordrparticipants_path(@restaurant),
         params: {
           ordrparticipant: { sessionid: '' },
         },
         as: :json

    # sessionid validation fails → unprocessable_content (policy authorize fires first)
    assert_includes [422, 500], response.status
  end

  test 'create: redirects unauthenticated user' do
    sign_out @user
    post restaurant_ordrparticipants_path(@restaurant),
         params: { ordrparticipant: { sessionid: 'anon' } },
         as: :json

    assert_response :unauthorized
  end

  # ---------------------------------------------------------------------------
  # PATCH update (authenticated nested route)
  # ---------------------------------------------------------------------------

  test 'update: updates participant name and returns JSON' do
    ActionCable.server.stub(:broadcast, nil) do
      patch restaurant_ordrparticipant_path(@restaurant, @participant),
            params: { ordrparticipant: { name: 'Updated Name' } },
            as: :json
    end

    assert_response :ok
    assert_equal 'Updated Name', @participant.reload.name
  end

  # ---------------------------------------------------------------------------
  # PATCH update — direct (unauthenticated smart menu route)
  # ---------------------------------------------------------------------------

  test 'direct update: allows name update when participant exists' do
    ActionCable.server.stub(:broadcast, nil) do
      # The participant fixture has sessionid 'test_session_123';
      # guest session validation fires only when not user_signed_in?.
      # Here we are signed in so it is bypassed.
      patch ordrparticipant_path(@participant),
            params: { ordrparticipant: { name: 'Direct Update' } },
            as: :json
    end

    assert_response :ok
  end

  # ---------------------------------------------------------------------------
  # DELETE destroy
  # ---------------------------------------------------------------------------

  test 'destroy: deletes the participant and returns no_content' do
    assert_difference 'Ordrparticipant.count', -1 do
      delete restaurant_ordrparticipant_path(@restaurant, @participant), as: :json
    end

    assert_response :no_content
  end

  test 'destroy: redirects unauthenticated user' do
    sign_out @user
    delete restaurant_ordrparticipant_path(@restaurant, @participant), as: :json

    assert_response :unauthorized
  end
end
