# frozen_string_literal: true

require 'test_helper'

class DwOrdersMvControllerTest < ActionDispatch::IntegrationTest
  test 'GET index redirects unauthenticated' do
    get dw_orders_mv_index_path
    assert_redirected_to new_user_session_path
  end
end
